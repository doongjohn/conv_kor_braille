pub fn isJamo(codepoint: u21) bool {
    return codepoint >= 'ㄱ' and codepoint <= 'ㅣ';
}

pub fn isComposite(codepoint: u21) bool {
    return codepoint >= '가' and codepoint <= '힣';
}

pub fn isCharacter(codepoint: u21) bool {
    return isJamo(codepoint) or isComposite(codepoint);
}
