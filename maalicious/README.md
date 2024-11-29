# maalicious

train a model to detect mailicous urls. probably return a percentage.

#### sources

- [https://www.kaggle.com/datasets/sid321axn/malicious-urls-datase](https://www.kaggle.com/datasets/sid321axn/malicious-urls-datase)
- [https://scikit-learn.org/stable/auto_examples/linear_model/plot_ols.html](https://scikit-learn.org/stable/auto_examples/linear_model/plot_ols.html)

### required

- virtualenv
- libtensorflow-lite

### running

Using the kaggle dataset, which has tagged urls.
Extract features and then train to create `tflite`.

This file will be used in `hypercore` for mailicious url prediction

```shell
python3 -m venv .venv

source .venv/bin/activate.fish # depending on your shell
make prepare
```
