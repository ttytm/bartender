# bartender

> Customizable bars for v term apps.

![smooth](https://user-images.githubusercontent.com/34311583/228962398-a7db6cea-3be3-4a21-ae95-a78f9e587a9c.gif)

## Getting started

- Install via vpm

  ```
  v install tobealive.bartender
  ```

  ```v
  // vpm installed modules require specification of the module provider.
  import tobealive.bartender
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

No API reference yet 🫣. Please refer to the sample files until the API has stabilized, and a reliable API reference can be provided with some confidence. Apologies for being too early.

## Showcase

<details open><summary><b>Simple example</b> &nbsp;<sub><sup>Toggle visibility...</sup></sub></summary>

![simple](https://user-images.githubusercontent.com/34311583/228962887-dbc76f93-4c82-43ed-95a1-964851fe3617.gif)

</details>

<details><summary><b>Color and style customizations.</b> &nbsp;<sub><sup>Toggle visibility...</sup></sub></summary>

![colors](https://user-images.githubusercontent.com/34311583/228962409-a5d9b3cb-b6d2-4b34-a2db-305249e95c82.gif)

</details>

<details><summary><b>Smooth bars.</b> &nbsp;<sub><sup>Toggle visibility...</sup></sub></summary>

![download](https://user-images.githubusercontent.com/34311583/228962385-2fd9e185-81a5-481a-aa9c-6101405bf64a.gif)

</details>

### Run examples

```
v run examples/<file>.v
```

## Outlook

Below are some of the things to look forward to.

- [x] Reader Interface
- [ ] Multiline
- [x] Time Remaining
- [ ] API Reference
- [ ] Concurrency
- [ ] Dynamic adjustment on term resize for all variants (basic width detection works)
- [ ] Extend visuals & customizability

## Anowledgements

- [Waqar144/progressbar][10] inspired the start of project.
- [console-rs/indicatif][20] serves as inspiration for further development.

[10]: https://github.com/Waqar144/progressbar
[20]: https://github.com/console-rs/indicatif
