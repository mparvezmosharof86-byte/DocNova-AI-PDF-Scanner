# DocNova: AI PDF & Scanner 📄⚡

> **Native Reverse-Engineering Document Reconstruction & Vector PDF Suite**  
> Developed for **Nova Studio 24** | Package: `com.novastudio24.docnova`

---

## 📌 Overview

**DocNova** is an enterprise-grade document scanner and desktop-level PDF engineering engine built with zero third-party Google ML dependencies. Unlike traditional scanners that save flattened camera photos with filters, DocNova uses an on-device AI layout decomposition and vector reconstruction pipeline to deconstruct scanned papers and rebuild them digitally on a pristine white canvas—producing native, razor-sharp vector PDFs as if digitally typeset.

---

## 🚀 Key Architectural Pillars

### 1. Zero-Click Realtime Auto-Capture (C++)
* **Blur Variance Detection:** Evaluates camera frames via Laplacian variance; auto-triggers when document is still.
* **Smart Quad Detection:** High-speed edge contouring and perspective rectification using OpenCV C++ core.

### 2. AI Document Reverse-Engineering (Python & ONNX Runtime)
* **Document Layout Analysis (DLA):** Segments headings, paragraphs, tables, stamps, and images.
* **Typography & Palette Extraction:** Samples text bounding boxes to match exact RGB colors, font weights, and proportional line heights.
* **Background Elimination:** Strips noisy paper background entirely, preserving only original vector elements and crisp graphics.

### 3. Native Vector Canvas Synthesis (Rust)
* **Digital Typesetting:** Writes true vector glyphs to a digital A4 canvas; creates searchable, selectable, and lightweight PDFs.
* **Dual Output Architecture:** Exports to pure vector PDF or high-resolution lossless raster formats (PNG/TIFF 300+ DPI).

### 4. Specialized Identity Scanner
* **ID Card Mode:** High-precision semantic crop ignoring hands and tables. Automatically balances and aligns Front and Back sides onto a single standard A4 sheet.
* **Passport & MRZ Reader:** Extracts identity data from the Machine Readable Zone without external cloud APIs.

### 5. High-Speed 1D/2D Barcode & QR Suite
* Pure C++ / Rust implementation powered by native ZXing engine.
* Real-time multi-format scanning and custom vector barcode/QR generator (custom gradients, eye patterns, and embedded logos).

---

## 🏗️ Repository Structure

```text
├── core-cv/          # Module 1: C++ Native Vision, Edge Detection & Warp
│   ├── CMakeLists.txt
│   └── src/
├── ai-pipeline/      # Module 2: Python / ONNX Layout Extraction & Typography Parser
│   ├── layout_engine.py
│   └── requirements.txt
├── pdf-engine/       # Module 3: Rust High-Performance Vector PDF Synthesizer
│   ├── Cargo.toml
│   └── src/
└── README.md
