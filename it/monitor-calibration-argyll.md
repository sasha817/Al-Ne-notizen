# Monitor Calibration with ArgyllCMS (i1 Display Pro)

> Written by Claude (Anthropic) from our calibration session on 2026-10-16.

How I calibrated and profiled my monitor with ArgyllCMS directly from the command line. I skipped DisplayCAL (its Windows build crashed) and X-Rite/Calibrite software (the X-Rite apps no longer support the device, and the Calibrite upgrade costs about €40).

## Setup

| Item | Value |
|---|---|
| Instrument | X-Rite i1 Display Pro (Argyll sees it as "i1Display3"), no driver needed |
| Monitor | Dell S3425DW (34", 3440×1440) on HDMI2 |
| GPU | NVIDIA GeForce RTX 2060 SUPER |
| OS | Windows 11 |
| Software | ArgyllCMS 3.5.0 in `C:\Argyll_V3.5.0\bin` (from argyllcms.com) |
| Use case | Photo editing (Lightroom/Photoshop) |

## Targets

| Setting | Value | Why |
|---|---|---|
| White point | 6500 K (D65) | Standard for screen/web photo work. 5000 K only for print matching under D50 light |
| Brightness | 120 cd/m² | Normal room light. Use 80–100 if printing |
| Tone curve | Gamma 2.2 | Standard |
| Profile type | Shaper + matrix (`-as`) | Robust and works everywhere. Use `-aX` (XYZ LUT) only for wide-gamut panels |

## ⚠️ PowerShell gotcha

Windows PowerShell splits arguments like `-g2.2` at the dot. The effect is gamma 2.0 plus a stray file named `.2.cal`. Either:
- **quote decimal args** in PowerShell: `'-g2.2' '-f1.0'`, or
- **use plain `cmd.exe`**, where no quotes are needed.

Always check that `dispcal` ends with `Written calibration file 'S3425DW.cal'`.

## Before starting

- Warm up the monitor for about 30 minutes.
- Monitor OSD: Custom Color preset, dynamic contrast / eco / ambient sensors OFF.
- No other calibration software running. i1Profiler is uninstalled and there is no X-Rite tray loader in Autostart.
- NVIDIA App → System → Anzeigen → Farbe: everything at defaults. "Standard" output, RGB, **Voll** (full range), 8 bpc, Helligkeit/Kontrast 100, Gamma 1, Digitale Farbanpassung 50 %, Farbton 0.

## Steps

All commands run in `C:\Argyll_V3.5.0\bin`.

### 0. (Optional) Check the instrument and display numbering

```
.\spotread.exe -c1 -yn          # sensor reads values → instrument OK
.\dispcal.exe -?                # display list + display types (-y) at the bottom
```

`-d1` = monitor 1, `-ye` = LCD white LED display type.

### 1. Calibrate (interactive adjustment, then about 5 min of measuring)

```
.\dispcal.exe -v -d1 -c1 -ye -qm -t6500 -b120 '-g2.2' '-f1.0' S3425DW
```

In the menu:
- **2) White point**: adjust the monitor's R/G/B gain until ΔE < 1. Last time I needed less green and got ΔE 0.6.
- **3) White level**: adjust the monitor's brightness to about 120 cd/m². Recheck after changing the RGB gains.
- **7) Continue on to calibration**

Output: `S3425DW.cal`

> Re-run without the interactive adjustment (monitor already set up): add `-m`.

### 2. Generate the test chart (only needed once; reusable)

```
.\targen.exe -v -d3 -G -e4 -s17 -g17 -f600 S3425DW
```

Output: `S3425DW.ti1` (600 patches)

### 3. Measure the chart with the calibration applied (about 10–15 min)

```
.\dispread.exe -v -d1 -c1 -ye -k S3425DW.cal S3425DW
```

Output: `S3425DW.ti3`. Don't touch the sensor or the monitor while it runs.

### 4. Build the profile

```
.\colprof.exe -v -qm -as -D "S3425DW Argyll" S3425DW
```

Output: `S3425DW.icm`. Check the last line: `avg err` < 1 is very good.

### 5. Install the profile (also loads the calibration curves)

```
.\dispwin.exe -d1 -I S3425DW.icm
```

No output = success.

## Windows settings (one-time)

1. Run `colorcpl` → **Geräte** → select the monitor → tick **"Eigene Einstellungen für das Gerät verwenden"**. *S3425DW Argyll* should be listed as **(Standard)**. Remove any old X-Rite profiles.
2. **Erweitert** → **Systemstandards ändern…** → **Erweitert** → tick **"Windows-Bildschirmkalibrierung verwenden"**. This loads the curves at login.
3. Restart Lightroom/Photoshop.
4. Don't touch the monitor OSD afterwards. Brightness, RGB gains and preset are part of the calibration.

## Verification (after reboot)

```
.\dispwin.exe -d1 -V S3425DW.icm     # should say "IS loaded"
```

Visual A/B check (optional):

```
.\dispwin.exe -d1 -c     # reset curves to linear (uncalibrated)
.\dispwin.exe -d1 -L     # load calibration again
```

If it says "NOT loaded": run `dispwin -d1 -L`, then check the "Windows-Bildschirmkalibrierung verwenden" setting and Autostart for other loaders.

## Reference results (2026-10-16)

- Calibration: average neutral error 0.31 ΔE, white point error 0.06 ΔE
- Profile: avg err 0.70, peak 2.06, gamma about 2.18–2.19, luminance 118.6 cd/m²
- Native panel: about 6440 K, gamma 2.24, black 0.051 cd/m², contrast 2352:1
- Video LUT depth: 8 bit (normal for consumer GPU over HDMI)

## Recalibration (every 2–3 months)

The chart is reusable, so skip step 2:

```
.\dispcal.exe -v -d1 -c1 -ye -qm -t6500 -b120 '-g2.2' '-f1.0' -m S3425DW
.\dispread.exe -v -d1 -c1 -ye -k S3425DW.cal S3425DW
.\colprof.exe -v -qm -as -D "S3425DW Argyll" S3425DW
.\dispwin.exe -d1 -I S3425DW.icm
```

Drop `-m` if the white point or brightness has drifted and needs readjusting on the monitor. Tip: back up the old `.cal/.ti3/.icm` files first, or use a dated base name.

## Troubleshooting notes

- **DisplayCAL 3.9.x (Python 3 fork) on Windows** crashed at measurement start with `pywintypes.error: (1, 'AttachConsole', 'Unzulässige Funktion')`. Argyll itself worked fine. The cause is DisplayCAL's console handling (wexpect), and switching the default terminal to Windows Console Host didn't help. Fallbacks: the old standalone DisplayCAL 3.8.9.3 (`https://displaycal.net/download/standalone/DisplayCAL-Setup.exe`), or the CLI route above.
- **Calibrite PROFILER** supports the X-Rite i1 Display Pro only with a paid upgrade license (about €40).
