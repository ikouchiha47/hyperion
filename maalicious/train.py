import whois
import sys
import datetime

import numpy as np
import pandas as pd
from ipaddress import ip_address
from urllib.parse import urlparse

# from sklearn.metrics import plot_confusion_matrix
# from sklearn.metrics import plot_roc_curve


from sklearn.model_selection import train_test_split


from tld import get_tld, Result

from sklearn.preprocessing import StandardScaler, LabelEncoder
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout, Input, BatchNormalization

# import seaborn as sns
# import matplotlib.pyplot as plt

# read dataset
data = pd.read_csv("./dataset/malicious_phish.csv")
# data2 = pd.read_csv("./dataset/new_data_urls.csv")
#
# data2["type"] = data2["status"].apply(lambda x: "phishing" if x == 0 else "benign")
# data2.drop("status", axis=1, inplace=True)
#
# data = pd.concat([data, data2], ignore_index=True)


# print stats
def print_stats(df):
    return
    print("peek")
    print(df.head())

    print("NaNs")
    print(df.isnull().sum())


# check %, for spaces
# check @, for
special_chars = ["@", "?", "-", "=", "#", "%", "+", ".", "$", "!", "*", ",", "//"]


def add_url_len():
    data["url_len"] = data["url"].apply(lambda x: len(str(x)))


def add_domain():
    data["tld"] = data["url"].apply(lambda u: get_top_level_domain(u))
    data["tld_len"] = data["tld"].apply(lambda u: 0 if u is None else len(u))


def using_https():
    data["is_https"] = data["url"].apply(lambda u: u.count("https") > 1)


def count_http():
    data["count_http"] = data["url"].apply(lambda u: u.count("http"))


def count_www():
    data["count_www"] = data["url"].apply(lambda u: u.count("www"))


def count_embeds():
    data["count_embed"] = data["url"].apply(lambda u: no_of_embed(u))


def count_path():
    data["count_path"] = data["url"].apply(lambda u: no_of_dir(u))


def using_ip():
    data["using_ip"] = data["url"].apply(lambda u: having_ip_address(u))


def count_digits():
    data["count_digits"] = data["url"].apply(lambda u: digit_count(u))


def count_letters():
    data["count_letters"] = data["url"].apply(lambda u: letter_count(u))


def count_special_chars():
    for ch in special_chars:
        data[f"count{ch}"] = data["url"].apply(lambda u: u.count(ch))


def hostname_length():
    data["hostname_len"] = data["url"].apply(lambda u: len(urlparse(u).netloc))


def is_abnormal_url():
    data["is_abnormal"] = data["url"].apply(lambda u: is_abnormal(u))


def decorate_data():
    rem = {"Category": {"benign": 0, "defacement": 1, "phishing": 2, "malware": 3}}
    data["Category"] = data["type"].map(rem["Category"])

    return data


## helpers


def get_top_level_domain(url):
    try:
        res: str | Result | None = get_tld(
            url, as_object=True, fail_silently=False, fix_protocol=True
        )
        if res is None or isinstance(res, str):
            return None
        pri_domain = res.parsed_url.netloc
    except Exception:
        pri_domain = None

    return pri_domain


def is_abnormal(url):
    try:
        domain = url.split("://")[-1].split("/")[0]

        whois_info = whois.whois(domain)

        creation_date = whois_info.creation_date
        if isinstance(creation_date, list):
            creation_date = creation_date[0]
        if creation_date and (datetime.datetime.now() - creation_date).days < 180:
            return 1

        if "REDACTED" in str(whois_info) or not whois_info.registrar:
            return 1

        # Add more conditions as needed, such as checking for suspicious registrars
        # For simplicity, we assume domains without a registrar are abnormal
        return 0  # Normal
    except Exception:
        # print(f"WHOIS lookup failed for {url}: {e}")
        return 1


def no_of_dir(url):
    urldir = urlparse(url).path
    return urldir.count("/")


def no_of_embed(url):
    urldir = urlparse(url).path
    return urldir.count("//")


def digit_count(url):
    return sum([1 for ch in url if ch.isnumeric()])


def letter_count(url):
    return sum([1 for ch in url if ch.isalpha()])


def having_ip_address(url):
    try:
        ip_address(url)
        return 1
    except Exception:
        return 0


def add_features():
    print_stats(data)

    add_url_len()
    print_stats(data)

    add_domain()
    print_stats(data)

    using_https()
    count_www()
    # print_stats(data)

    count_embeds()
    count_path()
    count_digits()
    # print_stats(data)

    count_letters()
    count_special_chars()
    hostname_length()
    # is_abnormal_url()

    # print_stats(data)
    using_ip()


def run():
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
    print(y_train[:5])
    print(y_test[:5])

    y_train = y_train.reshape(-1, 1)
    y_test = y_test.reshape(-1, 1)

    # Scale data
    scaler = StandardScaler()
    X_train = scaler.fit_transform(X_train)
    X_test = scaler.transform(X_test)

    print("shaper after transform", X_train.shape, X_test.shape)
    print("y shape after reshape", y_train.shape, y_test.shape)

    # Build a neural network

    # Model dimensions: 128 x 64 x 4
    # Dropout layer reduces overfitting.
    # Overfitting is when input outputs are too specific
    # Dropout removes values randomly https://en.wikipedia.org/wiki/Dilution_(neural_networks)#Dropout

    def build_advanced_model(input_dim):
        model = Sequential(
            [
                Input(shape=(input_dim,)),
                Dense(256, activation="relu"),
                BatchNormalization(),
                Dropout(0.3),
                Dense(128, activation="relu"),
                BatchNormalization(),
                Dropout(0.3),
                Dense(64, activation="relu"),
                Dropout(0.3),
                Dense(4, activation="softmax"),
            ]
        )
        model.compile(
            optimizer="adam",
            loss="sparse_categorical_crossentropy",
            metrics=["accuracy"],  # , "Precision", "Recall"
        )
        return model

    def build_model(input_dim):
        model = Sequential(
            [
                Input(shape=(input_dim,)),
                Dense(128, activation="relu"),
                Dropout(0.2),
                Dense(64, activation="relu"),
                Dropout(0.2),
                Dense(4, activation="softmax"),
            ]
        )
        model.compile(
            optimizer="adam",
            loss="sparse_categorical_crossentropy",
            metrics=["accuracy"],
        )
        return model

    def train_and_save(model):
        # Train the model
        _ = model.fit(
            X_train,
            y_train,
            validation_data=(X_test, y_test),
            epochs=20,
            batch_size=32,
            class_weight={0: 1.0, 1: 1.0, 2: 10.0, 3: 10.0},
        )

        # Evaluate the model
        _, accuracy = model.evaluate(X_test, y_test)
        print(f"Test Accuracy: {accuracy * 100:.2f}%")

        # Save the model in TFLite format
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        # converter.target_spec.supported_ops = [tf.lite.OpsSet.SELECT_TF_OPS]
        # converter.experimental_new_converter = True

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
    model = build_advanced_model(X_train.shape[1])
    train_and_save(model)


if __name__ == "__main__":
    print("initial state")
    print(data.head())

    data = decorate_data()
    print("decorated")
    print(data.head())

    add_features()
    print("features")
    print(data.head())

    run()

# from sklearn.metrics import confusion_matrix, classification_report, accuracy_score
# from sklearn.tree import DecisionTreeClassifier
# from sklearn.ensemble import (
#     RandomForestClassifier,
#     AdaBoostClassifier,
#     ExtraTreesClassifier,
# )
# from sklearn.neighbors import KNeighborsClassifier
# from sklearn.linear_model import SGDClassifier
# from sklearn.naive_bayes import GaussianNB
# models = [
#     DecisionTreeClassifier,
#     RandomForestClassifier,
#     AdaBoostClassifier,
#     KNeighborsClassifier,
#     SGDClassifier,
#     ExtraTreesClassifier,
#     GaussianNB,
# ]
#
# accuracy_test = []
# for m in models:
#     print("#############################################")
#     print("######-Model =>\033[07m {} \033[0m".format(m))
#     model_ = m()
#     model_.fit(X_train, y_train)
#     pred = model_.predict(X_test)
#     acc = accuracy_score(pred, y_test)
#     accuracy_test.append(acc)
#     print("Test Accuracy :\033[32m \033[01m {:.2f}% \033[30m \033[0m".format(acc * 100))
#     print("\033[01m              Classification_report \033[0m")
#     print(classification_report(y_test, pred))
#     print("\033[01m             Confusion_matrix \033[0m")
#     cf_matrix = confusion_matrix(y_test, pred)
#     plot_ = sns.heatmap(cf_matrix / np.sum(cf_matrix), annot=True, fmt="0.2%")
#     plt.show()
#     print("\033[31m###################- End -###################\033[0m")
