# bartender

https://user-images.githubusercontent.com/34311583/225964767-c3521d61-ebd4-49c3-8aa0-859e4d638690.mov

<br>

## Getting started

- Install via vpm

  ```
  v install tobealive.bartender
  ```

  ```v
  import tobealive.bartender // vpm installed modules require specification of the module provider.
  ```

- Or clone the repository to a preferred location and link it to your `.vmodules` directory.

  ```
  git clone https://github.com/tobealive/bartender.git
  cd bartender
  ln -s $(pwd)/ ~/.vmodules/bartender
  ```

  ```v
  import bartender
  ```

## Usage

For now, please refer to the sample files for usage.

### Run examples

```
v run examples/<file>.v
```

## Outlook

Bartender is in early development. Below are some of the things to look forward to.

- [ ] ReaderWriter Implementation
- [ ] Multiline
- [ ] Time Remaining
- [ ] Documentation
- [ ] Concurrency
- [ ] Screenwidth
- [ ] Extend visuals & customizability

## Anowledgements

- [Waqar144/progressbar][10] inspired the start of project.
- [console-rs/indicatif][20] serves as inspiration for further development.

[10]: https://github.com/Waqar144/progressbar
[20]: https://github.com/console-rs/indicatif
