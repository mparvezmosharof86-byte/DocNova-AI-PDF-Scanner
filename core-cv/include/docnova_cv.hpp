/**
 * ==============================================================================
 * Project: DocNova: AI PDF & Scanner
 * Package: com.novastudio24.docnova
 * Component: Native Computer Vision Engine (C++20)
 * File: docnova_cv.hpp
 * ==============================================================================
 */

#ifndef DOCNOVA_CV_HPP
#define DOCNOVA_CV_HPP

#include <opencv2/core.hpp>
#include <vector>
#include <string>

namespace docnova::cv_engine {

    /**
     * @brief স্ক্যানিং মোড নির্ধারণকারী এনাম
     */
    enum class ScanMode {
        DOCUMENT,       // সাধারণ A4/ডকুমেন্ট পেপার
        ID_CARD_FRONT,  // আইডি কার্ডের সামনের পাশ
        ID_CARD_BACK,   // আইডি কার্ডের পেছনের পাশ
        PASSPORT        // আন্তর্জাতিক পাসপোর্ট মোড
    };

    /**
     * @brief শনাক্তকরণ স্ট্যাটাস
     */
    enum class DetectionStatus {
        SUCCESS,            // নিখুঁতভাবে ডকুমেন্ট পাওয়া গেছে ও স্থির আছে
        BLURRY_FRAME,       // ফ্রেম ব্লার বা ক্যামেরা নড়াচড়া করছে
        NO_DOCUMENT_FOUND,  // কোনো কাগজ ফ্রেমে আসেনি
        UNSTABLE_CORNERS    // কোণগুলো পুরোপুরি স্পষ্ট নয়
    };

    /**
     * @brief স্বয়ংক্রিয় স্ক্যানের ফলাফল ডেটা স্ট্রাকচার
     */
    struct DetectionResult {
        DetectionStatus status;
        std::vector<cv::Point2f> corners; // ৪টি কোণা: [Top-Left, Top-Right, Bottom-Right, Bottom-Left]
        double blur_score;                 // ব্লার স্কোর (ভ্যারিয়েন্স মান)
        double confidence;                 // ডিটেকশন কনফিডেন্স (০.০ থেকে ১.০)
        bool ready_for_autocapture;        // ক্লিক ছাড়াই অটো ক্যাপচারের উপযোগী কি না
    };

    /**
     * @brief DocNova কোর ভিশন ইঞ্জিন ক্লাস
     */
    class DocNovaVisionEngine {
    public:
        DocNovaVisionEngine();
        ~DocNovaVisionEngine() = default;

        /**
         * @brief ফ্রেমের ব্লারনেস নির্ণয় করে (Laplacian Variance Method)
         * @param frame ইনপুট ক্যামেরা ফ্রেম
         * @return ডাবল ভ্যারিয়েন্স স্কোর (কম হলে ব্লার, বেশি হলে শার্প)
         */
        double calculateBlurVariance(const cv::Mat& frame);

        /**
         * @brief লাইভ ক্যামেরার ফ্রেম থেকে ডকুমেন্টের ৪ কোণা শনাক্ত করে
         * @param frame ক্যামেরা থেকে আসা ফ্রেম
         * @param mode স্ক্যানিং মোড (ডকুমেন্ট, আইডি কার্ড নাকি পাসপোর্ট)
         * @return DetectionResult অবজেক্ট
         */
        DetectionResult analyzeFrame(const cv::Mat& frame, ScanMode mode = ScanMode::DOCUMENT);

        /**
         * @brief ৪ কোণার ভিত্তিতে ডকুমেন্টকে সোজা ও ফ্ল্যাট করে (Perspective Rectification)
         * @param src আসল হাই-রেজোলিউশন ইমেজ
         * @param corners ৪টি কোণার পয়েন্ট
         * @return ফ্ল্যাট এবং ক্রপ করা cv::Mat ইমেজ
         */
        cv::Mat warpPerspectiveDoc(const cv::Mat& src, const std::vector<cv::Point2f>& corners);

        /**
         * @brief আইডি কার্ডের ফ্রন্ট ও ব্যাক সাইডকে নিয়ম অনুযায়ী সাদা A4 পেজে সাজিয়ে দেয়
         * @param frontWarped সোজা করা ফ্রন্ট সাইড ইমেজ
         * @param backWarped সোজা করা ব্যাক সাইড ইমেজ
         * @return ডিজিটাল A4 পেপার সাইজে দুই পাশ সাজানো ইমেজ
         */
        cv::Mat stitchDualIDCard(const cv::Mat& frontWarped, const cv::Mat& backWarped);

    private:
        double blur_threshold_;     // ন্যূনতম শার্পনেস থ্রেশহোল্ড
        double min_area_ratio_;     // স্ক্রিনের কত শতাংশ কাগজের হওয়া দরকার

        std::vector<cv::Point2f> orderPoints(const std::vector<cv::Point>& pts);
        cv::Mat preprocessForContours(const cv::Mat& input);
    };

} // namespace docnova::cv_engine

#endif // DOCNOVA_CV_HPP
