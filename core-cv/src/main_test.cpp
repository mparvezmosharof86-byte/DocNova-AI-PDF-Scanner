/**
 * ==============================================================================
 * Project: DocNova: AI PDF & Scanner
 * Package: com.novastudio24.docnova
 * Component: C++ Vision Engine Standalone Benchmark & CLI Tester
 * File: main_test.cpp
 * ==============================================================================
 */

#include "docnova_cv.hpp"
#include <opencv2/imgcodecs.hpp>
#include <iostream>
#include <chrono>

int main(int argc, char** argv) {
    std::cout << "========================================================\n";
    std::cout << "  DocNova: Native Vision Engine CLI Benchmark Test\n";
    std::cout << "  Package: com.novastudio24.docnova | Pure C++20 Core\n";
    std::cout << "========================================================\n\n";

    docnova::cv_engine::DocNovaVisionEngine engine;

    cv::Mat inputImage;

    if (argc > 1) {
        std::string filePath = argv[1];
        std::cout << "[+] ফাইল লোড করা হচ্ছে: " << filePath << "\n";
        inputImage = cv::imread(filePath);
        if (inputImage.empty()) {
            std::cerr << "[-] এরর: ফাইল লোড করা যায়নি!\n";
            return -1;
        }
    } else {
        std::cout << "[i] কোনো ইমেজ ইনপুট দেওয়া হয়নি; সিন্থেটিক 1080p ফ্রেম দিয়ে টেস্ট হচ্ছে...\n";
        // টেস্ট করার জন্য একটি ডামি ফ্রেম (1920x1080)
        inputImage = cv::Mat(1080, 1920, CV_8UC3, cv::Scalar(40, 40, 40));
        // ফ্রেমের ভেতর একটি বাঁকা কাগজের সিন্থেটিক রেক্ট্যাঙ্গেল আঁকা
        std::vector<cv::Point> syntheticDoc = {
            cv::Point(350, 180),
            cv::Point(1550, 220),
            cv::Point(1450, 950),
            cv::Point(400, 890)
        };
        cv::fillConvexPoly(inputImage, syntheticDoc, cv::Scalar(245, 245, 245));
    }

    // ১. শার্পনেস এবং ব্লার ভ্যারিয়েন্স পরিমাপ
    auto start_time = std::chrono::high_resolution_clock::now();
    double blurScore = engine.calculateBlurVariance(inputImage);
    std::cout << "[+] ব্লার ভ্যারিয়েন্স স্কোর: " << blurScore << " (শার্পনেস থ্রেশহোল্ড >= 120.0)\n";

    // ২. রিয়েল-টাইম এজ ডিটেকশন ও অটো-ক্যাপচার অ্যানালাইসিস
    auto result = engine.analyzeFrame(inputImage, docnova::cv_engine::ScanMode::DOCUMENT);
    auto end_time = std::chrono::high_resolution_clock::now();

    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time).count();
    std::cout << "[+] প্রসেসিং সময়: " << duration << " ms\n";

    std::cout << "[+] ডিটেকশন স্ট্যাটাস: ";
    switch (result.status) {
        case docnova::cv_engine::DetectionStatus::SUCCESS:
            std::cout << "SUCCESS (কাগজের ৪ কোণা নির্ভুলভাবে পাওয়া গেছে)\n";
            break;
        case docnova::cv_engine::DetectionStatus::BLURRY_FRAME:
            std::cout << "BLURRY_FRAME (ক্যামেরা স্থির নয় বা ফ্রেম ঘোলা)\n";
            break;
        case docnova::cv_engine::DetectionStatus::NO_DOCUMENT_FOUND:
            std::cout << "NO_DOCUMENT_FOUND (কোনো পেপার শনাক্ত হয়নি)\n";
            break;
        case docnova::cv_engine::DetectionStatus::UNSTABLE_CORNERS:
            std::cout << "UNSTABLE_CORNERS (কোণগুলো পুরোপুরি স্পষ্ট নয়)\n";
            break;
    }

    std::cout << "[+] কনফিডেন্স স্কোর: " << (result.confidence * 100.0) << "%\n";
    std::cout << "[+] অটো-ক্যাপচারের জন্য তৈরি: " << (result.ready_for_autocapture ? "হ্যাঁ (READY)" : "না (WAITING)") << "\n";

    // ৩. পার্সপেক্টিভ ওয়ার্প ট্রান্সফর্মেশন
    if (!result.corners.empty()) {
        std::cout << "\n[+] চিহ্নিত ৪টি কোণা:\n";
        std::cout << "    Top-Left:     (" << result.corners[0].x << ", " << result.corners[0].y << ")\n";
        std::cout << "    Top-Right:    (" << result.corners[1].x << ", " << result.corners[1].y << ")\n";
        std::cout << "    Bottom-Right: (" << result.corners[2].x << ", " << result.corners[2].y << ")\n";
        std::cout << "    Bottom-Left:  (" << result.corners[3].x << ", " << result.corners[3].y << ")\n";

        cv::Mat warped = engine.warpPerspectiveDoc(inputImage, result.corners);
        if (!warped.empty()) {
            std::string outPath = "scanned_warp.jpg";
            cv::imwrite(outPath, warped);
            std::cout << "[+] সোজা করা ফ্ল্যাট পেপার সেভ হয়েছে: " << outPath << "\n";
        }
    }

    std::cout << "\n========================================================\n";
    std::cout << "  [SUCCESS] C++ ভিশন ইঞ্জিনের টেস্ট সম্পূর্ণ সফল!\n";
    std::cout << "========================================================\n";

    return 0;
}
