import sys, os

import numpy as np
import pandas as pd
# from sklearn.metrics import plot_confusion_matrix
# from sklearn.metrics import plot_roc_curve


from sklearn.model_selection import train_test_split

from sklearn.preprocessing import StandardScaler, LabelEncoder
import tensorflow as tf


sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# import seaborn as sns
# import matplotlib.pyplot as plt

from extractfeatures import (
    add_url_len,
    add_domain,
    using_https,
    count_www,
    count_embeds,
    count_path,
    count_digits,
    count_letters,
    count_special_chars,
    hostname_length,
    count_query_params,
    using_ip,
)

from modelbuilders import (
    model_multiclass,
    model_multiclass_2,
    model_binaryclass,
    preprocess_urls_tokens,
)


# print stats
def print_stats(df):
    return
    print("peek")
    print(df.head())

    print("NaNs")
    print(df.isnull().sum())


def decorate_data_binaryclass(data):
    rem = {"Category": {"benign": 1, "defacement": 0, "phishing": 0, "malware": 0}}
    data["Category"] = data["type"].map(rem["Category"]).astype(int)

    return data


def decorate_data_multiclass(data):
    rem = {"Category": {"benign": 0, "defacement": 1, "phishing": 2, "malware": 3}}
    data["Category"] = data["type"].map(rem["Category"]).astype(int)

    return data


def add_features(data):
    print_stats(data)

    add_url_len(data)
    print_stats(data)

    add_domain(data)
    print_stats(data)

    using_https(data)
    count_www(data)
    # print_stats(data)

    count_embeds(data)
    count_path(data)
    count_digits(data)
    # print_stats(data)

    count_letters(data)
    count_special_chars(data)
    hostname_length(data)
    count_query_params(data)

    # is_abnormal_url()
    # print_stats(data)
    using_ip(data)


def run(data):
    # X, vocab_size, max_sequence_length = preprocess_urls_tokens(data)
    X = data.drop(["url", "type", "Category", "tld"], axis=1)

    y = data["Category"]

    label_encoder = LabelEncoder()
    y_encoded = label_encoder.fit_transform(y).reshape(-1)

    X_train, X_test, y_train, y_test = train_test_split(
        X.values, y_encoded, test_size=0.2, random_state=2
    )

    print(
        "start training",
        data.shape,
        X.shape,
        X_train.shape,
        X_test.shape,
        y_train.shape,
        y_test.shape,
    )

    y_train = y_train.reshape(-1, 1)
    y_test = y_test.reshape(-1, 1)

    # Scale data
    scaler = StandardScaler()
    X_train = scaler.fit_transform(X_train)
    X_test = scaler.transform(X_test)

    print("shaper after transform", X_train.shape, X_test.shape)
    print("y shape after reshape", y_train.shape, y_test.shape)

    print("x train Nans", np.any(np.isnan(X_train)))
    print("x test Nans", np.any(np.isnan(X_test)))

    print("y train Nan", np.any(np.isnan(y_train)))
    print("Y test Nan", np.any(np.isnan(y_test)))

    # Build a neural network

    # Model dimensions: 128 x 64 x 4
    # Dropout layer reduces overfitting.
    # Overfitting is when input outputs are too specific
    # Dropout removes values randomly https://en.wikipedia.org/wiki/Dilution_(neural_networks)#Dropout
    def train_and_save(model):
        # Train the model
        _ = model.fit(
            X_train,
            y_train,
            validation_data=(X_test, y_test),
            epochs=20,
            batch_size=32,
        )

        # Evaluate the model
        accuracy = model.evaluate(X_test, y_test)
        # print(f"Test Accuracy: {accuracy * 100:.2f}%")
        print(f"Test Accuracy: {accuracy}%")

        # Save the model in TFLite format
        converter = tf.lite.TFLiteConverter.from_keras_model(model)

        tflite_model = converter.convert()

        if tflite_model is None:
            print("failed to initialize converter")
            sys.exit(1)

        # Save the TFLite model to a file
        with open("phishing_detection.tflite", "wb") as f:
            f.write(tflite_model)

        print("TFLite model saved as phishing_detection.tflite")

    print(X_train.shape, "shape")
    print("Unique categories in y_train:", np.unique(y_train))

    # model = build_model(X_train.shape[1])
    model = model_binaryclass(X_train.shape[1])
    train_and_save(model)


if __name__ == "__main__":
    # read dataset
    data = pd.read_csv("./dataset/malicious_phish.csv")
    data2 = pd.read_csv("./dataset/new_data_urls.csv")
    #
    data2["type"] = data2["status"].apply(lambda x: "phishing" if x == 0 else "benign")
    data2.drop("status", axis=1, inplace=True)
    #
    data = pd.concat([data, data2], ignore_index=True)

    print("initial state")
    print(data.head())

    data = decorate_data_binaryclass(data)
    print("decorated")
    print(data.head())

    add_features(data)
    print("features")
    print(data.head())

    run(data)
