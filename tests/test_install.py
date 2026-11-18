"""Security boundaries for generated keyboard access rules."""

import unittest

import install


class RuleScopeTests(unittest.TestCase):
    def test_udev_pattern_syntax_cannot_widen_keyboard_match(self):
        for name in ("Keyboard|Other Keyboard", "Keyboard*", "Keyboard?", "Keyboard[12]"):
            with self.subTest(name=name), self.assertRaises(ValueError):
                install.render([name])

    def test_uaccess_tag_is_set_before_systemd_applies_seat_acls(self):
        self.assertLess(install.RULE.name, "73-seat-late.rules")


if __name__ == "__main__":
    unittest.main()
