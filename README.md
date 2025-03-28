# Convert Korean to Braille

Based on: [2024 개정 한국 점자 규정](https://korean.go.kr/front_eng/down/down_02V.do?etc_seq=710&pageIndex=1)

## Building & Testing

- Tested Zig version: `0.14.0-dev.2032+c563ba6b1`
- Build: `zig build`
- Test: `zig build test --summary all`

## Features

- **단독으로 쓰인 자모**
    - 자음자나 모음자가 단독으로 쓰일 때에는 해당 글자 앞에 온표 `⠿`을 적어 나
타내며, 자음자는 받침으로 적는다.
- **초,중,종성 조합**
    - 안: `⠣⠒`
    - 닭: `⠊⠣⠂⠁`
    - ...
- **약어**
    - 그래서: `⠁⠎`
    - 그러나: `⠁⠉`
    - 그러면: `⠁⠒`
    - 그러므로: `⠁⠢`
    - 그런데: `⠁⠝`
    - 그리고: `⠁⠥`
    - 그리하여: `⠁⠱`
- **모음 연쇄**
    - 모음자에 '예'가 붙어 나올 때에는 그 사이에 구분표 `⠤`을 적어 나타낸다.
    - 'ㅑ, ㅘ, ㅜ, ㅝ'에 '애'가 붙어 나올 때에는 두 모음자 사이에 구분표 `⠤`을 적어 나타낸다.

## TODO

- 약자
- 숫자
- 문장부호
- 영어
