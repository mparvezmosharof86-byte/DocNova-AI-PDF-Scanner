/**
 * ==============================================================================
 * Project: DocNova: AI PDF & Scanner
 * Package: com.novastudio24.docnova
 * Component: Native Rust Vector PDF Synthesizer & Local QR Stamp Engine
 * File: main.rs
 * ==============================================================================
 */

use printpdf::*;
use qrcode::QrCode;
use serde::Deserialize;
use std::fs::File;
use std::io::BufReader;
use std::path::Path;

#[derive(Debug, Deserialize)]
struct Element {
    #[serde(rename = "type")]
    element_type: String,
    text: String,
    x: f64,
    y: f64,
    width: f64,
    height: f64,
    font_size: f64,
    is_bold: bool,
    color_rgb: Vec<u8>,
}

#[derive(Debug, Deserialize)]
struct DocumentMetadata {
    original_width: f64,
    original_height: f64,
    aspect_ratio: f64,
    total_text_blocks: usize,
}

#[derive(Debug, Deserialize)]
struct DocumentData {
    version: String,
    metadata: DocumentMetadata,
    elements: Vec<Element>,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("========================================================");
    println!("  DocNova: Native Rust Vector PDF Synthesizer Core");
    println!("  Package: com.novastudio24.docnova | Pure Vector Canvas");
    println!("========================================================\n");

    let json_path = "../ai-pipeline/document_structure.json";
    let fallback_json = "document_structure.json";

    let target_path = if Path::new(json_path).exists() {
        json_path
    } else if Path::new(fallback_json).exists() {
        fallback_json
    } else {
        println!("[i] স্ট্রাকচার্ড JSON পাওয়া যায়নি; ডেমো ভেক্টর পেজ প্রস্তুত হচ্ছে...");
        create_demo_json(fallback_json)?;
        fallback_json
    };

    println!("[+] JSON স্ট্রাকচার লোড হচ্ছে: {}", target_path);
    let file = File::open(target_path)?;
    let reader = BufReader::new(file);
    let doc_data: DocumentData = serde_json::from_reader(reader)?;

    // ১. নিখুঁত ফ্রেশ ডিজিটাল A4 ক্যানভাস তৈরি (210mm x 297mm)
    let a4_width_mm = 210.0;
    let a4_height_mm = 297.0;

    let (doc, page1, layer1) = PdfDocument::new(
        "DocNova AI Reconstructed Document",
        Mm(a4_width_mm),
        Mm(a4_height_mm),
        "Pristine Layer",
    );

    let current_layer = doc.get_page(page1).get_layer(layer1);

    // ২. হাই-রেজোলিউশন ভেক্টর ফন্ট ইনিশিয়ালাইজেশন
    let font_regular = doc.add_builtin_font(BuiltinFont::Helvetica)?;
    let font_bold = doc.add_builtin_font(BuiltinFont::HelveticaBold)?;

    // পিক্সেল কোঅর্ডিনেট থেকে A4 মিলিমিটারের ম্যাথমেটিক্যাল স্কেলিং
    let scale_x = a4_width_mm / doc_data.metadata.original_width;
    let scale_y = a4_height_mm / doc_data.metadata.original_height;

    println!("[+] ভেক্টর টেক্সট বসানো শুরু হচ্ছে (মোট ব্লক: {})...", doc_data.elements.len());

    for el in &doc_data.elements {
        if el.element_type != "text" || el.text.is_empty() {
            continue;
        }

        // PDF এর উৎপত্তি নিচ-বামে (Bottom-Left), তাই Y এক্সিস রূপান্তর
        let pdf_x = Mm(el.x * scale_x);
        let pdf_y = Mm(a4_height_mm - ((el.y + el.height) * scale_y));

        // কালার নরম্যালাইজেশন (০.০ থেকে ১.০)
        let r = el.color_rgb.get(0).copied().unwrap_or(0) as f32 / 255.0;
        let g = el.color_rgb.get(1).copied().unwrap_or(0) as f32 / 255.0;
        let b = el.color_rgb.get(2).copied().unwrap_or(0) as f32 / 255.0;

        current_layer.set_fill_color(Color::Rgb(Rgb::new(r, g, b, None)));

        let active_font = if el.is_bold {
            &font_bold
        } else {
            &font_regular
        };

        // আনুপাতিক ফন্ট পয়েন্ট সাইজ
        let pt_size = (el.font_size * 0.45).clamp(6.0, 72.0);

        current_layer.use_text(&el.text, pt_size, pdf_x, pdf_y, active_font);
    }

    // ৩. নো-গুগল নেটিভ QR কোড স্ট্যাম্প (ডকুমেন্টের নিচের কোনায় সিকিউরিটি সিল)
    println!("[+] নো-গুগল নেটিভ কিউআর ভেরিফিকেশন স্ট্যাম্প আঁকা হচ্ছে...");
    let qr = QrCode::new(b"DocNova-AI-Verified-Document-NovaStudio24")?;
    let qr_modules = qr.to_vec();
    let qr_width = qr.width();

    let qr_origin_x = 175.0; // ডানে নিচের মার্জিন (mm)
    let qr_origin_y = 12.0;
    let qr_box_size = 0.65;  // প্রতিটি কিউআর পয়েন্টের মিলিমিটার সাইজ

    current_layer.set_fill_color(Color::Rgb(Rgb::new(0.1, 0.1, 0.1, None)));

    for y in 0..qr_width {
        for x in 0..qr_width {
            let idx = y * qr_width + x;
            if qr_modules[idx] {
                let rect_x = qr_origin_x + (x as f64 * qr_box_size);
                let rect_y = qr_origin_y + ((qr_width - y) as f64 * qr_box_size);

                let points = vec![
                    (Point::new(Mm(rect_x), Mm(rect_y)), false),
                    (Point::new(Mm(rect_x + qr_box_size), Mm(rect_y)), false),
                    (Point::new(Mm(rect_x + qr_box_size), Mm(rect_y + qr_box_size)), false),
                    (Point::new(Mm(rect_x), Mm(rect_y + qr_box_size)), false),
                ];
                let line = Line {
                    points,
                    is_closed: true,
                    has_fill: true,
                    has_stroke: false,
                };
                current_layer.add_polygon(line);
            }
        }
    }

    // ৪. খাঁটি ভেক্টর PDF ফাইল এক্সপোর্ট
    let output_pdf_name = "AI_Pristine_Reconstructed.pdf";
    let mut out_file = std::io::BufWriter::new(File::create(output_pdf_name)?);
    doc.save(&mut out_file)?;

    println!("\n========================================================");
    println!("  [SUCCESS] ফ্রেশ ভেক্টর PDF তৈরি সম্পন্ন!");
    println!("  আউটপুট ফাইল: {}", output_pdf_name);
    println!("========================================================");

    Ok(())
}

fn create_demo_json(path: &str) -> Result<(), Box<dyn std::error::Error>> {
    let demo_content = r#"{
  "version": "1.0.0",
  "metadata": {
    "original_width": 1200.0,
    "original_height": 1600.0,
    "aspect_ratio": 0.75,
    "total_text_blocks": 2
  },
  "elements": [
    {
      "type": "text",
      "text": "DocNova AI Vector Engine - Pristine Reconstructed",
      "x": 120.0,
      "y": 180.0,
      "width": 800.0,
      "height": 50.0,
      "font_size": 36.0,
      "is_bold": true,
      "color_rgb": [20, 20, 20]
    },
    {
      "type": "text",
      "text": "This document was reverse-engineered onto a clean digital canvas.",
      "x": 120.0,
      "y": 280.0,
      "width": 750.0,
      "height": 30.0,
      "font_size": 22.0,
      "is_bold": false,
      "color_rgb": [180, 20, 20]
    }
  ]
}"#;
    std::fs::write(path, demo_content)?;
    Ok(())
}
