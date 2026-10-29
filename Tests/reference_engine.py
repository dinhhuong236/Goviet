"""Bản tham chiếu Python của TelexEngine.swift — dùng để kiểm tra thuật toán.
Chạy: python3 reference_engine.py cases.tsv
"""
import sys

VOWELS = set("aeiouy")
NONE, HAT, BREVE, HORN, STROKE = range(5)

PLAIN = {
    ("a", NONE): "a", ("a", HAT): "â", ("a", BREVE): "ă",
    ("e", NONE): "e", ("e", HAT): "ê",
    ("o", NONE): "o", ("o", HAT): "ô", ("o", HORN): "ơ",
    ("u", NONE): "u", ("u", HORN): "ư",
    ("i", NONE): "i", ("y", NONE): "y",
    ("d", NONE): "d", ("d", STROKE): "đ",
}
# thứ tự: sắc, huyền, hỏi, ngã, nặng
TONED = {
    "a": "áàảãạ", "ă": "ắằẳẵặ", "â": "ấầẩẫậ", "e": "éèẻẽẹ", "ê": "ếềểễệ",
    "i": "íìỉĩị", "o": "óòỏõọ", "ô": "ốồổỗộ", "ơ": "ớờởỡợ",
    "u": "úùủũụ", "ư": "ứừửữự", "y": "ýỳỷỹỵ",
}
TONE_KEYS = {"s": 1, "f": 2, "r": 3, "x": 4, "j": 5}

INITIALS = set("""b c ch d đ g gh gi h k kh l m n ng ngh nh p ph qu r s t th tr v x""".split()) | {""}
FINALS = {"", "c", "ch", "m", "n", "ng", "nh", "p", "t"}
NUCLEI = set("""a ă â e ê i o ô ơ u ư y
ai ao au ay âu ây eo êu ia iê iu oa oă oe oi ôi ơi oo ua uâ ue uê ui uô uơ uy ưa ưi ưu ươ yê
iêu oai oao oay oeo uây uôi uya uyê uyu ươi ươu yêu""".split())


class Letter:
    def __init__(self, base, upper, mod=NONE, from_w=False):
        self.base, self.upper, self.mod, self.from_w = base, upper, mod, from_w

    def plain(self):
        return PLAIN.get((self.base, self.mod), self.base)


class Engine:
    def __init__(self, old_style=True):
        self.old_style = old_style
        self.reset()

    def reset(self):
        self.letters, self.tone, self.raw = [], 0, ""

    @property
    def composing(self):
        return bool(self.letters)

    # --- cấu trúc âm tiết -------------------------------------------------
    def vowel_run(self):
        """(start, end) của cụm nguyên âm cuối cùng, end là exclusive."""
        end = None
        for i in range(len(self.letters) - 1, -1, -1):
            if self.letters[i].base in VOWELS:
                end = i + 1
                break
        if end is None:
            return None
        start = end - 1
        while start > 0 and self.letters[start - 1].base in VOWELS:
            start -= 1
        return start, end

    def nucleus(self):
        run = self.vowel_run()
        if not run:
            return [], False
        s, e = run
        idx = list(range(s, e))
        if len(idx) > 1 and s > 0:
            prev, first = self.letters[s - 1], self.letters[s]
            if prev.base == "q" and first.base == "u" and first.mod == NONE:
                idx = idx[1:]
            elif prev.base == "g" and first.base == "i":
                idx = idx[1:]
        return idx, e < len(self.letters)

    def tone_index(self):
        idx, has_final = self.nucleus()
        if not idx:
            return None
        modified = [i for i in idx if self.letters[i].mod in (HAT, BREVE, HORN)]
        if modified:
            return modified[-1]
        if len(idx) == 1:
            return idx[0]
        if len(idx) == 2:
            if has_final:
                return idx[1]
            pair = self.letters[idx[0]].base + self.letters[idx[1]].base
            if not self.old_style and pair in ("oa", "oe", "uy"):
                return idx[1]
            return idx[0]
        return idx[1]

    # --- hiển thị ------------------------------------------------------------
    def render(self):
        ti = self.tone_index() if self.tone else None
        out = []
        for i, l in enumerate(self.letters):
            c = l.plain()
            if i == ti:
                c = TONED[c][self.tone - 1]
            out.append(c.upper() if l.upper else c)
        return "".join(out)

    def is_valid(self):
        s = "".join(l.plain() for l in self.letters)
        i = 0
        while i < len(s) and s[i] not in "aăâeêioôơuưy":
            i += 1
        c1 = s[:i]
        j = i
        while j < len(s) and s[j] in "aăâeêioôơuưy":
            j += 1
        v, c2 = s[i:j], s[j:]
        if any(ch in "aăâeêioôơuưy" for ch in c2):
            return False
        if c1 == "q" and v.startswith("u") and len(v) > 1:
            c1, v = "qu", v[1:]
        elif c1 == "g" and v.startswith("i") and len(v) > 1:
            c1, v = "gi", v[1:]
        if c1 not in INITIALS or c2 not in FINALS or v not in NUCLEI:
            return False
        if c2 in ("c", "ch", "p", "t") and self.tone not in (1, 5):
            return False
        return True

    # --- xử lý phím ------------------------------------------------------------
    def append(self, ch, **kw):
        self.letters.append(Letter(ch.lower(), ch.isupper(), **kw))

    def undo(self, ch):
        self.append(ch)
        self.raw = None  # người dùng chủ động hoàn tác -> không tự khôi phục nữa

    def key(self, ch):
        """Nhận một chữ cái ASCII."""
        k = ch.lower()
        if self.raw is not None:
            self.raw += ch
        idx, _ = self.nucleus()
        has_vowel = any(l.base in VOWELS for l in self.letters)

        if k in TONE_KEYS or k == "z":
            if not has_vowel:
                return self.append(ch)
            if k == "z":
                if self.tone:
                    self.tone = 0
                else:
                    self.append(ch)
                return
            t = TONE_KEYS[k]
            if self.tone == t:
                self.tone = 0
                return self.undo(ch)
            self.tone = t
            return

        if k in "aeo":
            run = self.vowel_run()
            if run:
                for i in range(run[1] - 1, run[0] - 1, -1):
                    l = self.letters[i]
                    if l.base == k:
                        if l.mod == HAT:
                            l.mod = NONE
                            return self.undo(ch)
                        l.mod = HAT
                        return
            return self.append(ch)

        if k == "w":
            last = self.letters[-1] if self.letters else None
            if last and last.from_w and last.mod == HORN:
                self.letters.pop()
                return self.undo(ch)
            if not idx:
                return self.append("U" if ch.isupper() else "u", mod=HORN, from_w=True)
            L = self.letters
            for a, b in zip(idx, idx[1:]):
                if L[a].base == "u" and L[b].base == "o":
                    if L[a].mod == HORN and L[b].mod == HORN:
                        L[a].mod = L[b].mod = NONE
                        return self.undo(ch)
                    L[a].mod = L[b].mod = HORN
                    return
            bases = [L[i].base for i in idx]
            target = None
            if "oa" in "".join(bases):
                target = next(i for i in idx if L[i].base == "a"), BREVE
            else:
                for base, mod in (("o", HORN), ("u", HORN), ("a", BREVE)):
                    found = [i for i in idx if L[i].base == base]
                    if found:
                        target = found[-1], mod
                        break
            if target is None:
                return self.append(ch)
            i, mod = target
            if L[i].mod == mod:
                L[i].mod = NONE
                return self.undo(ch)
            L[i].mod = mod
            return

        if k == "d" and self.letters and self.letters[0].base == "d":
            first = self.letters[0]
            if first.mod == NONE:
                first.mod = STROKE
                return
            if first.mod == STROKE:
                first.mod = NONE
                return self.undo(ch)

        self.append(ch)

    def backspace(self):
        if not self.letters:
            return False
        self.letters.pop()
        self.raw = None
        if not any(l.base in VOWELS for l in self.letters):
            self.tone = 0
        return True

    def commit(self, auto_restore=True):
        if not self.letters:
            return ""
        out = self.render()
        if auto_restore and self.raw is not None and not self.is_valid():
            out = self.raw
        self.reset()
        return out


def type_text(text, old_style=True):
    e = Engine(old_style)
    out = []
    for ch in text:
        if ch.isascii() and ch.isalpha():
            e.key(ch)
        else:
            out.append(e.commit() + ch)
    out.append(e.commit())
    return "".join(out)


if __name__ == "__main__":
    fails = 0
    total = 0
    for line in open(sys.argv[1], encoding="utf-8"):
        if not line.strip() or line.startswith("#"):
            continue
        style, keys, want = line.rstrip("\n").split("\t")
        got = type_text(keys, style == "old")
        total += 1
        if got != want:
            fails += 1
            print(f"FAIL [{style}] {keys!r}: got {got!r}, want {want!r}")
    print(f"{total - fails}/{total} passed")
    sys.exit(1 if fails else 0)
