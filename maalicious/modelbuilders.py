from pandas.io.parquet import json
from tensorflow.keras.models import Model, Sequential
from tensorflow.keras.layers import (
    Input,
    Embedding,
    Conv1D,
    MaxPooling1D,
    Dense,
    Dropout,
    Flatten,
    Attention,
    BatchNormalization,
)

from tensorflow.keras.preprocessing.text import Tokenizer
from tensorflow.keras.preprocessing.sequence import pad_sequences


def model_multiclass(input_dim):
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


def model_multiclass_2(input_dim):
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


def model_binaryclass_attention(vocab_size, input_dim):
    # Input layer
    input_layer = Input(shape=(input_dim,))

    # Embedding layer
    embedding_layer = Embedding(
        input_dim=vocab_size, output_dim=64, input_length=input_dim
    )(input_layer)

    # CNN layer
    cnn_layer = Conv1D(filters=32, kernel_size=3, activation="relu")(embedding_layer)
    cnn_layer = MaxPooling1D(pool_size=2)(cnn_layer)

    # Attention layer
    attention_layer = Attention()([cnn_layer, cnn_layer])

    # Fully connected layers
    flatten_layer = Flatten()(attention_layer)
    dense_layer = Dense(128, activation="relu")(flatten_layer)
    dropout_layer = Dropout(0.5)(dense_layer)
    output_layer = Dense(1, activation="sigmoid")(
        dropout_layer
    )  # Binary classification

    # Compile model
    model = Model(inputs=input_layer, outputs=output_layer)
    model.compile(
        optimizer="adam", loss="binary_crossentropy", metrics=["accuracy", "Recall"]
    )

    return model


def model_binaryclass(input_dim):
    model = Sequential(
        [
            Input(shape=(input_dim,)),
            Dense(128, activation="relu"),
            Dropout(0.2),
            Dense(64, activation="relu"),
            Dropout(0.2),
            Dense(1, activation="sigmoid"),
        ]
    )
    model.compile(
        optimizer="adam",
        loss="binary_crossentropy",
        metrics=["accuracy", "Recall", "Precision"],
    )
    return model


def model_binaryclass_2(vocab_size, input_dim):
    # Input layer
    input_layer = Input(shape=(input_dim,))

    # Embedding layer
    embedding_layer = Embedding(
        input_dim=vocab_size, output_dim=64, input_length=input_dim
    )(input_layer)

    # CNN layers
    cnn_layer = Conv1D(filters=32, kernel_size=3, activation="relu")(embedding_layer)
    cnn_layer = MaxPooling1D(pool_size=2)(cnn_layer)

    # Fully connected layers
    flatten_layer = Flatten()(cnn_layer)
    dense_layer = Dense(128, activation="relu")(flatten_layer)
    dropout_layer = Dropout(0.5)(dense_layer)
    output_layer = Dense(1, activation="sigmoid")(
        dropout_layer
    )  # Binary classification

    # Compile model
    model = Model(inputs=input_layer, outputs=output_layer)
    model.compile(
        optimizer="adam", loss="binary_crossentropy", metrics=["accuracy", "Recall"]
    )

    return model


def preprocess_urls_tokens(data):
    tokenizer = Tokenizer(char_level=False, oov_token="<OOV>")
    tokenizer.fit_on_texts(data["url"])

    sequences = tokenizer.texts_to_sequences(data["url"])
    max_sequence_length = 100
    vocab_size = len(tokenizer.word_index) + 1

    padded_sequences = pad_sequences(
        sequences, maxlen=max_sequence_length, truncate="post", padding="post"
    )
    tokenizer_json = tokenizer.to_json()

    with open("tokenizer.json", "w") as f:
        json.dump(tokenizer_json, f)

    return padded_sequences, vocab_size, max_sequence_length
