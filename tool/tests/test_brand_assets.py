import hashlib
import json
from pathlib import Path
import struct
import unittest
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[2]
ANDROID_RES = ROOT / "android/app/src/main/res"
IOS_ASSETS = ROOT / "ios/Runner/Assets.xcassets"
BRAND = ROOT / "assets/branding"
INTER = ROOT / "assets/fonts/inter"


def png_size(path: Path) -> tuple[int, int]:
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        raise AssertionError(f"Not a PNG: {path}")
    return struct.unpack(">II", data[16:24])


def png_is_opaque(path: Path) -> bool:
    data = path.read_bytes()
    # PNG color types 4 and 6 carry alpha; tRNS adds transparency to types
    # 0, 2 or 3. App Store icons must have neither.
    return data[25] not in (4, 6) and b"tRNS" not in data


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class BrandAssetsTest(unittest.TestCase):
    def test_approved_masters_are_unchanged(self) -> None:
        expected = {
            "saydin-app-icon-ios-1024.png":
                "90bf66438dcd12ecb4bce3693153591723956ed66b02b6ec985e0277ea09fb1b",
            "saydin-play-store-icon-512.png":
                "d95a7b6c4e8118df3da9f21607f4dd9ed55e25600993d6f85d396574ea146219",
            "saydin-symbol-on-light-1024.png":
                "21065f1770a75cba1eb9f75673eb3f5c75ccc8a016b280f7dfbed76eb88ae374",
            "saydin-symbol-on-dark-1024.png":
                "aff8fb51cc371c97d8688f4537247339d41533e694279538f4115159eec5e0ac",
        }
        for filename, digest in expected.items():
            self.assertEqual(sha256(BRAND / filename), digest, filename)

    def test_runtime_brand_lockups_are_approved_transparent_exports(self) -> None:
        expected = {
            "saydin-logo-horizontal-light-h512.png": (
                (1396, 512),
                "3261604ef7b8c387f54a499f1247c1bdb2459e8c95912b44b3950dd85738686d",
            ),
            "saydin-logo-horizontal-dark-h512.png": (
                (1396, 512),
                "e59984e1070189c79f09aa9d2829223bcda81878513ed3c05f3b81e10aba90fb",
            ),
            "saydin-symbol-fullcolor-256.png": (
                (256, 256),
                "f2efcb46dd1b36801e0a0dd677045872918384e17228d39cb91cb45550beeb9d",
            ),
        }
        for filename, (dimensions, digest) in expected.items():
            asset = BRAND / filename
            self.assertEqual(png_size(asset), dimensions, filename)
            self.assertFalse(png_is_opaque(asset), filename)
            self.assertEqual(sha256(asset), digest, filename)

    def test_bundled_inter_fonts_and_license_are_pinned(self) -> None:
        expected = {
            "Inter-Regular.ttf":
                "40d692fce188e4471e2b3cba937be967878f631ad3ebbbdcd587687c7ebe0c82",
            "Inter-Medium.ttf":
                "97ad806f526e41546d46365bb3a393145f75b7b1568913db74549ad8b8dba872",
            "Inter-SemiBold.ttf":
                "78a843fade9d4612a5567302fb595b56976eb5fcebf4fea5a5912d638bafcde3",
            "Inter-Bold.ttf":
                "288316099b1e0a47a4716d159098005eef7c0066921f34e3200393dbdb01947f",
            "OFL.txt":
                "262481e844521b326f5ecd053e59b98c8b2da78c8ee1bdbb6e8174305e54935a",
        }
        for filename, digest in expected.items():
            self.assertEqual(sha256(INTER / filename), digest, filename)

    def test_ios_icon_catalog_has_all_expected_dimensions(self) -> None:
        catalog = IOS_ASSETS / "AppIcon.appiconset"
        contents = json.loads((catalog / "Contents.json").read_text())
        dimensions = {
            image["filename"]: round(
                float(image["size"].split("x", 1)[0])
                * float(image["scale"].removesuffix("x"))
            )
            for image in contents["images"]
        }
        self.assertEqual(len(dimensions), 15)
        for filename, dimension in dimensions.items():
            self.assertEqual(png_size(catalog / filename), (dimension, dimension))
            self.assertTrue(png_is_opaque(catalog / filename), filename)
        self.assertEqual(
            sha256(catalog / "Icon-App-1024x1024@1x.png"),
            sha256(BRAND / "saydin-app-icon-ios-1024.png"),
        )

    def test_android_launcher_and_adaptive_resources(self) -> None:
        expected = {
            "mdpi": 48,
            "hdpi": 72,
            "xhdpi": 96,
            "xxhdpi": 144,
            "xxxhdpi": 192,
        }
        for density, dimension in expected.items():
            icon = ANDROID_RES / f"mipmap-{density}/ic_launcher.png"
            self.assertEqual(png_size(icon), (dimension, dimension))

        v26 = ET.parse(ANDROID_RES / "mipmap-anydpi-v26/ic_launcher.xml").getroot()
        v33 = ET.parse(ANDROID_RES / "mipmap-anydpi-v33/ic_launcher.xml").getroot()
        self.assertEqual(v26.tag, "adaptive-icon")
        self.assertEqual(v33.tag, "adaptive-icon")
        self.assertEqual([child.tag for child in v26], ["background", "foreground"])
        self.assertEqual(
            [child.tag for child in v33],
            ["background", "foreground", "monochrome"],
        )

    def test_light_and_dark_launch_assets_are_real_images(self) -> None:
        for path in (
            ANDROID_RES / "drawable-nodpi/launch_image.png",
            ANDROID_RES / "drawable-night-nodpi/launch_image.png",
        ):
            self.assertEqual(png_size(path), (112, 112))

        launch = IOS_ASSETS / "LaunchImage.imageset"
        expected = {
            "LaunchImage.png": 156,
            "LaunchImage@2x.png": 312,
            "LaunchImage@3x.png": 468,
            "LaunchImage-Dark.png": 156,
            "LaunchImage-Dark@2x.png": 312,
            "LaunchImage-Dark@3x.png": 468,
        }
        for filename, dimension in expected.items():
            self.assertEqual(png_size(launch / filename), (dimension, dimension))


if __name__ == "__main__":
    unittest.main()
