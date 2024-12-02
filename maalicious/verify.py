from urllib.parse import urlparse
import tensorflow as tf
import numpy as np
import sys
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from extractfeatures import (
    digit_count,
    get_top_level_domain,
    having_ip_address,
    letter_count,
    no_of_dir,
    no_of_embed,
    total_query_params,
)

interpreter = tf.lite.Interpreter(model_path="phishing_detection.tflite")
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# print("Input details:", input_details)


special_chars = ["@", "?", "-", "=", "#", "%", "+", ".", "$", "!", "*", ",", "//"]


def preprocess_url(url):
    url_length = len(url)
    tld = get_top_level_domain(url)
    tldLen = 0 if tld is None else len(tld)

    is_https = 1 if url.startswith("https") else 0
    n_www = url.count("www")

    n_count_specials = []
    for ch in special_chars:
        n_count_specials.append(url.count(ch))

    n_embeds = no_of_embed(url)
    n_path = no_of_dir(url)
    has_ip = having_ip_address(url)
    n_digits = digit_count(url)
    n_letters = letter_count(url)
    hostname_len = len(urlparse(url).netloc)
    n_qs = total_query_params(url)

    features = [
        url_length,
        tldLen,
        is_https,
        n_www,
        n_embeds,
        n_path,
        n_digits,
        n_letters,
    ]
    features.extend(n_count_specials)
    features.extend([hostname_len, has_ip, n_qs])

    print(len(features), "n_features")

    return np.array(features, dtype=np.float32)


def predict(url, n_features=24):
    input_value = preprocess_url(url)
    input_value = np.reshape(input_value, (1, n_features))

    interpreter.set_tensor(input_details[0]["index"], input_value)
    interpreter.invoke()

    output_data = interpreter.get_tensor(output_details[0]["index"])
    print(f"Prediction probability: {output_data}")

    # Interpret the result
    predicted_class = np.argmax(output_data)
    print("predicted class", predicted_class, output_data)


uus = [
    "https://google.com",
    "https://www.google.com",
    "http://www.marketingbyinternet.com/mo/e56508df639f6ce7d55c81ee3fcd5ba8/",
    "000011accesswebform.godaddysites.com",
]

[predict(u) for u in uus]
