# Automated Measurement of Myofiber Cross-Sectional Area Using ImageJ

This repository provides an ImageJ/Fiji macro for automated and semi-manual quantification of myofiber cross-sectional area (CSA) from histological muscle sections using segmentation masks.
The workflow integrates web-based deep-learning segmentation with objective morphometric filtering and optional user-guided curation to ensure robust and reproducible CSA measurements.

---

## Overview

The macro performs batch analysis of muscle cross-section images by converting labeled segmentation masks into individual fiber regions of interest (ROIs). ROIs are filtered based on geometric criteria, measured on the corresponding original images, and exported in formats suitable for downstream statistical analysis.

Key features include:
- Integration with web-based Cellpose-SAM segmentation
- Automated exclusion of border-touching fibers
- Area- and circularity-based ROI filtering
- Optional manual ROI inspection and correction
- Batch-compatible output generation
- Consolidated CSA datasets across multiple images

---

## Software Requirements

- Fiji (ImageJ), latest stable release

### Required Plugins

- MorphoLibJ  
  Required for label image processing, including:
  - Remove Border Labels
  - Label Map to ROIs

- Standard Fiji components:
  - ROI Manager

Note: MorphoLibJ is not installed by default in Fiji and must be installed prior to running this macro.

### Plugin Installation

In Fiji:
1. Help → Update…
2. Click Manage update sites
3. Enable IJPB/MorphoLibJ
4. Apply changes and restart Fiji

No additional third-party plugins are required.

---

## Input Data

### Image Requirements

- Original images  
  Histological muscle cross-sections (e.g., H&E staining, laminin or dystrophin immunofluorescence).

- Mask images  
  Labeled segmentation masks generated from the original images using the web-based Cellpose-SAM interface  
  (https://huggingface.co/spaces/mouseland/cellpose).

  Original images should be uploaded to the Cellpose-SAM web interface, and the resulting label mask output files should be downloaded and used directly as input for this macro.
  Each myofiber must be represented by a unique integer label in the mask image.

Original image filenames must partially match their corresponding mask filenames.

---

## User-Defined Parameters

At runtime, users specify the following parameters:

| Parameter | Description |
|----------|-------------|
| Image scale | Pixel-to-length conversion (e.g., pixels/µm) |
| Minimum area | Lower CSA threshold |
| Maximum area | Upper CSA threshold |
| Minimum circularity | Shape constraint (0–1) |
| Manual ROI review | Enables interactive ROI correction |

All parameters are recorded in an analysis summary file for reproducibility.

---

## Image Processing and CSA Quantification

1. Segmentation mask generation  
   Myofiber segmentation is performed externally using the web-based Cellpose-SAM tool. Resulting labeled mask images are downloaded and supplied to the macro.

2. Mask preprocessing  
   Labeled masks are imported into Fiji, and border-touching fibers are removed using MorphoLibJ to exclude incomplete cross-sections. Remaining labels are converted into ROIs.

3. ROI filtering  
   ROIs are filtered according to user-defined area and circularity thresholds. Filtered ROIs are written back into a new labeled mask image.

4. CSA measurement  
   Filtered ROIs are applied to the corresponding original images. CSA and additional morphometric parameters are measured using ImageJ’s measurement framework.

5. Manual ROI refinement (optional)  
   When enabled, users visually inspect ROIs and manually remove or adjust erroneous segmentations. Updated ROIs are used to regenerate filtered masks prior to final measurement.

---

## Output Files

For each image, the macro generates:
- CSA measurement tables (.csv)
- ROI files (.zip)
- ROI overlay images (.png)

In addition, the following global outputs are produced:
- Filtered label masks (.tif)
- Merged CSA dataset across all images (merged_area_data.csv)
- Analysis summary log documenting all input parameters and ROI counts

---

## Reproducibility and Quality Control

All analysis parameters, timestamps, and ROI counts before and after filtering are automatically recorded.
Optional manual review allows exclusion of segmentation artifacts while preserving batch-processing reproducibility.

---

## Applications

This macro is suitable for:
- Quantification of myofiber hypertrophy and atrophy
- Comparative muscle phenotyping across genotypes or treatments
- Aging- and disease-associated muscle remodeling studies

---

## Code Availability

The ImageJ macro is freely available in this repository.

---

## Author

Jae-Ryong KIM

---

## License

This software is distributed under the MIT License, permitting unrestricted use, modification, and redistribution with appropriate attribution.
