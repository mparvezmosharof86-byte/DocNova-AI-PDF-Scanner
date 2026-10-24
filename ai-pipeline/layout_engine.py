"""
==============================================================================
Project: DocNova: AI PDF & Scanner
Package: com.novastudio24.docnova
Component: AI Document Layout Decomposition & Typography Reverse-Engineer
File: layout_engine.py
==============================================================================
"""

import os
import json
import cv2
import numpy as np
import pytesseract
from PIL import Image

class DocNovaLayoutEngine:
    def __init__(self, confidence_threshold: int = 40):
        self.conf_threshold = confidence_threshold

    def extract_ink_color(self, roi_bgr: np.ndarray) -> list:
        """
        একটি অক্ষরের বাউন্ডারি বক্স থেকে ব্যাকগ্রাউন্ড বাদ দিয়ে শুধু আসল লেখার কালির রঙ (RGB) বের করে।
        """
        if roi_bgr.size == 0:
            return [0, 0, 0]

        gray_roi = cv2.cvtColor(roi_bgr, cv2.COLOR_BGR2GRAY)
        
        # Otsu থ্রেশহোল্ডিং দিয়ে কাগজ ও লেখার কালি আলাদা করা
        _, text_mask = cv2.threshold(gray_roi, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
        
        ink_pixels = roi_bgr[text_mask == 255]
        
        if len(ink_pixels) > 0:
            # কালির পিক্সেলগুলোর মিডিয়ান ভ্যালু নেওয়া (যাতে শ্যাডো বা নয়েজ না আসে)
            median_bgr = np.median(ink_pixels, axis=0)
            return [int(median_bgr[2]), int(median_bgr[1]), int(median_bgr[0])] # BGR to RGB
        else:
            return [0, 0, 0] # ডিফল্ট ক্রিস্প ব্ল্যাক

    def analyze_document(self, image_path: str, output_json: str, assets_dir: str = "extracted_assets") -> dict:
        """
        ডকুমেন্ট স্ক্যান ইমেজ পড়ে টেক্সট, কোঅর্ডিনেট, ফন্ট ও কালার নিয়ে স্ট্রাকচার্ড ডেটা তৈরি করে।
        """
        if not os.path.exists(image_path):
            raise FileNotFoundError(f"[-] ইমেজ ফাইল পাওয়া যায়নি: {image_path}")

        os.makedirs(assets_dir, exist_ok=True)

        image_bgr = cv2.imread(image_path)
        img_h, img_w = image_bgr.shape[:2]
        image_rgb = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB)

        print(f"[+] ডকুমেন্ট সাইজ: {img_w}x{img_h} px | AI লেআউট অ্যানালাইসিস শুরু হচ্ছে...")

        # OCR ও বাউন্ডিং বক্স ডিটেকশন
        ocr_data = pytesseract.image_to_data(image_rgb, output_type=pytesseract.Output.DICT)

        elements = []
        num_boxes = len(ocr_data['text'])

        for i in range(num_boxes):
            text = ocr_data['text'][i].strip()
            conf = int(ocr_data['conf'][i])

            if conf >= self.conf_threshold and len(text) > 0:
                x = ocr_data['left'][i]
                y = ocr_data['top'][i]
                w = ocr_data['width'][i]
                h = ocr_data['height'][i]

                # বাউন্ডারি বক্স বাফার ভ্যালিডেশন
                x_safe = max(0, x)
                y_safe = max(0, y)
                w_safe = min(w, img_w - x_safe)
                h_safe = min(h, img_h - y_safe)

                roi = image_bgr[y_safe:y_safe + h_safe, x_safe:x_safe + w_safe]
                color_rgb = self.extract_ink_color(roi)

                # ফন্ট সাইজ আনুপাতিক স্কেলিং (ডকুমেন্ট হাইট ভিত্তিক)
                computed_font_size = max(8, int(h_safe * 0.72))

                elements.append({
                    "type": "text",
                    "text": text,
                    "x": x_safe,
                    "y": y_safe,
                    "width": w_safe,
                    "height": h_safe,
                    "font_size": computed_font_size,
                    "is_bold": bool(h_safe > 25), # বড় অক্ষরের জন্য বোল্ড হিউরিস্টিক
                    "color_rgb": color_rgb
                })

        payload = {
            "version": "1.0.0",
            "metadata": {
                "original_width": img_w,
                "original_height": img_h,
                "aspect_ratio": round(img_w / img_h if img_h > 0 else 1.0, 4),
                "total_text_blocks": len(elements)
            },
            "elements": elements
        }

        with open(output_json, 'w', encoding='utf-8') as f:
            json.dump(payload, f, ensure_ascii=False, indent=2)

        print(f"[+] লেআউট বিশ্লেষণ সম্পন্ন: {len(elements)} টি ভেক্টর টেক্সট উপাদান তৈরি হয়েছে।")
        print(f"[+] আউটপুট সেভ হয়েছে: {output_json}")
        return payload

if __name__ == "__main__":
    test_image_name = "scanned_warp.jpg"
    output_json_name = "document_structure.json"

    # টেস্ট ফাইল না থাকলে একটি সিন্থেটিক পেপার তৈরি করে টেস্ট চালানো হবে
    if not os.path.exists(test_image_name):
        print("[i] টেস্ট ইমেজ পাওয়া যায়নি; সিন্থেটিক পেজ বানিয়ে ভ্যালিডেশন চলছে...")
        canvas = np.ones((1600, 1200, 3), dtype=np.uint8) * 240
        # ডামি টেক্সট আঁকা
        cv2.putText(canvas, "DocNova AI Vector Engine", (150, 200), cv2.FONT_HERSHEY_SIMPLEX, 1.8, (20, 20, 20), 4)
        cv2.putText(canvas, "Status: Reconstructed Pristine Page", (150, 320), cv2.FONT_HERSHEY_SIMPLEX, 1.0, (180, 20, 20), 2)
        cv2.imwrite(test_image_name, canvas)

    engine = DocNovaLayoutEngine()
    engine.analyze_document(test_image_name, output_json_name)
