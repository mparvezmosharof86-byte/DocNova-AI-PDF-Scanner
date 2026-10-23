/**
 * ==============================================================================
 * Project: DocNova: AI PDF & Scanner
 * Package: com.novastudio24.docnova
 * Component: Native Computer Vision Engine (C++20 Implementation)
 * File: docnova_cv.cpp
 * ==============================================================================
 */

#include "docnova_cv.hpp"
#include <opencv2/imgproc.hpp>
#include <cmath>
#include <algorithm>

namespace docnova::cv_engine {

    DocNovaVisionEngine::DocNovaVisionEngine()
        : blur_threshold_(120.0), min_area_ratio_(0.12) {}

    double DocNovaVisionEngine::calculateBlurVariance(const cv::Mat& frame) {
        if (frame.empty()) return 0.0;

        cv::Mat gray, laplacianImage;
        if (frame.channels() == 3) {
            cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);
        } else {
            gray = frame;
        }

        cv::Laplacian(gray, laplacianImage, CV_64F);
        cv::Scalar mean, stddev;
        cv::meanStdDev(laplacianImage, mean, stddev);

        // ভ্যারিয়েন্স = স্ট্যান্ডার্ড ডেভিয়েশনের বর্গ
        return stddev.val[0] * stddev.val[0];
    }

    cv::Mat DocNovaVisionEngine::preprocessForContours(const cv::Mat& input) {
        cv::Mat gray, blurred, edged;
        if (input.channels() == 3) {
            cv::cvtColor(input, gray, cv::COLOR_BGR2GRAY);
        } else {
            gray = input;
        }

        // ডকুমেন্টের ভেতরের সূক্ষ্ম টেক্সট স্মুথ করে শুধু বর্ডার ধরার জন্য
        cv::GaussianBlur(gray, blurred, cv::Size(5, 5), 0);
        cv::Canny(blurred, edged, 50, 150);

        // ভাঙা এজগুলোকে জোড়া লাগানোর জন্য ডাইলেশন
        cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(3, 3));
        cv::dilate(edged, edged, kernel);

        return edged;
    }

    std::vector<cv::Point2f> DocNovaVisionEngine::orderPoints(const std::vector<cv::Point>& pts) {
        std::vector<cv::Point2f> rect(4);
        std::vector<float> sum(4), diff(4);

        for (size_t i = 0; i < 4; ++i) {
            sum[i] = static_cast<float>(pts[i].x + pts[i].y);
            diff[i] = static_cast<float>(pts[i].y - pts[i].x);
        }

        // Top-Left: x + y সর্বনিম্ন
        rect[0] = pts[std::min_element(sum.begin(), sum.end()) - sum.begin()];
        // Bottom-Right: x + y সর্বোচ্চ
        rect[2] = pts[std::max_element(sum.begin(), sum.end()) - sum.begin()];
        // Top-Right: y - x সর্বনিম্ন
        rect[1] = pts[std::min_element(diff.begin(), diff.end()) - diff.begin()];
        // Bottom-Left: y - x সর্বোচ্চ
        rect[3] = pts[std::max_element(diff.begin(), diff.end()) - diff.begin()];

        return rect;
    }

    DetectionResult DocNovaVisionEngine::analyzeFrame(const cv::Mat& frame, ScanMode mode) {
        DetectionResult result;
        result.status = DetectionStatus::NO_DOCUMENT_FOUND;
        result.confidence = 0.0;
        result.ready_for_autocapture = false;

        if (frame.empty()) return result;

        result.blur_score = calculateBlurVariance(frame);
        if (result.blur_score < blur_threshold_) {
            result.status = DetectionStatus::BLURRY_FRAME;
            return result;
        }

        cv::Mat processed = preprocessForContours(frame);
        std::vector<std::vector<cv::Point>> contours;
        cv::findContours(processed, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);

        double total_frame_area = static_cast<double>(frame.cols * frame.rows);
        double max_area = 0.0;
        std::vector<cv::Point> best_quad;

        for (const auto& contour : contours) {
            double area = cv::contourArea(contour);
            if (area < (total_frame_area * min_area_ratio_)) continue;

            double peri = cv::arcLength(contour, true);
            std::vector<cv::Point> approx;
            cv::approxPolyDP(contour, approx, 0.02 * peri, true);

            // ৪টি ভার্টেক্স এবং কনভেক্স শেপ কি না
            if (approx.size() == 4 && cv::isContourConvex(approx)) {
                if (area > max_area) {
                    max_area = area;
                    best_quad = approx;
                }
            }
        }

        if (best_quad.empty()) {
            result.status = DetectionStatus::NO_DOCUMENT_FOUND;
            return result;
        }

        result.corners = orderPoints(best_quad);
        result.status = DetectionStatus::SUCCESS;
        result.confidence = std::min(1.0, max_area / (total_frame_area * 0.85));

        // আইডি কার্ড মোডে স্ট্যান্ডার্ড রেশিও যাচাই (ISO/IEC 7810 ID-1 = ~1.586)
        if (mode == ScanMode::ID_CARD_FRONT || mode == ScanMode::ID_CARD_BACK) {
            float width = std::hypot(result.corners[1].x - result.corners[0].x, result.corners[1].y - result.corners[0].y);
            float height = std::hypot(result.corners[3].x - result.corners[0].x, result.corners[3].y - result.corners[0].y);
            float ratio = (height > 0) ? (width / height) : 0.0f;

            if (ratio >= 1.2f && ratio <= 1.8f && result.confidence > 0.5) {
                result.ready_for_autocapture = true;
            }
        } else {
            // সাধারণ A4 ডকুমেন্ট ক্যাপচার রুল
            if (result.confidence > 0.45 && result.blur_score >= blur_threshold_) {
                result.ready_for_autocapture = true;
            }
        }

        return result;
    }

    cv::Mat DocNovaVisionEngine::warpPerspectiveDoc(const cv::Mat& src, const std::vector<cv::Point2f>& corners) {
        if (src.empty() || corners.size() != 4) return cv::Mat();

        float widthA = std::hypot(corners[2].x - corners[3].x, corners[2].y - corners[3].y);
        float widthB = std::hypot(corners[1].x - corners[0].x, corners[1].y - corners[0].y);
        int maxWidth = std::max(static_cast<int>(widthA), static_cast<int>(widthB));

        float heightA = std::hypot(corners[1].x - corners[2].x, corners[1].y - corners[2].y);
        float heightB = std::hypot(corners[0].x - corners[3].x, corners[0].y - corners[3].y);
        int maxHeight = std::max(static_cast<int>(heightA), static_cast<int>(heightB));

        std::vector<cv::Point2f> dst = {
            cv::Point2f(0.0f, 0.0f),
            cv::Point2f(static_cast<float>(maxWidth - 1), 0.0f),
            cv::Point2f(static_cast<float>(maxWidth - 1), static_cast<float>(maxHeight - 1)),
            cv::Point2f(0.0f, static_cast<float>(maxHeight - 1))
        };

        cv::Mat matrix = cv::getPerspectiveTransform(corners, dst);
        cv::Mat warped;
        cv::warpPerspective(src, warped, matrix, cv::Size(maxWidth, maxHeight), cv::INTER_CUBIC);

        return warped;
    }

    cv::Mat DocNovaVisionEngine::stitchDualIDCard(const cv::Mat& frontWarped, const cv::Mat& backWarped) {
        // স্ট্যান্ডার্ড A4 সাইজ 300 DPI ক্যানভাস (2480 x 3508 পিক্সেল) সম্পূর্ণ সাদা
        const int A4_WIDTH = 2480;
        const int A4_HEIGHT = 3508;
        cv::Mat a4_canvas(A4_HEIGHT, A4_WIDTH, CV_8UC3, cv::Scalar(255, 255, 255));

        // আইডি কার্ডের ফিক্সড প্রিন্ট সাইজ (1011 x 638 পিক্সেল)
        const int CARD_TARGET_W = 1011;
        const int CARD_TARGET_H = 638;

        cv::Mat resized_front, resized_back;
        if (!frontWarped.empty()) {
            cv::resize(frontWarped, resized_front, cv::Size(CARD_TARGET_W, CARD_TARGET_H), 0, 0, cv::INTER_AREA);
        }
        if (!backWarped.empty()) {
            cv::resize(backWarped, resized_back, cv::Size(CARD_TARGET_W, CARD_TARGET_H), 0, 0, cv::INTER_AREA);
        }

        // সেন্টার অ্যালাইনমেন্ট কোঅর্ডিনেট
        int x_pos = (A4_WIDTH - CARD_TARGET_W) / 2;
        int y_pos_front = (A4_HEIGHT / 4) - (CARD_TARGET_H / 2);
        int y_pos_back = (3 * A4_HEIGHT / 4) - (CARD_TARGET_H / 2);

        // ফ্রন্ট সাইড ক্যানভাসে বসানো
        if (!resized_front.empty()) {
            cv::Rect roi_front(x_pos, y_pos_front, CARD_TARGET_W, CARD_TARGET_H);
            resized_front.copyTo(a4_canvas(roi_front));
            cv::rectangle(a4_canvas, roi_front, cv::Scalar(220, 220, 220), 2); // সূক্ষ্ম ফ্রেম
        }

        // ব্যাক সাইড ক্যানভাসে বসানো
        if (!resized_back.empty()) {
            cv::Rect roi_back(x_pos, y_pos_back, CARD_TARGET_W, CARD_TARGET_H);
            resized_back.copyTo(a4_canvas(roi_back));
            cv::rectangle(a4_canvas, roi_back, cv::Scalar(220, 220, 220), 2); // সূক্ষ্ম ফ্রেম
        }

        return a4_canvas;
    }

} // namespace docnova::cv_engine
