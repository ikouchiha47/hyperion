
#ifndef TFLITEMODEL_H
#define TFLITEMODEL_H

#include <qlogging.h>
#include <QObject>
#include <QtQml/qqml.h>
#include <QDebug>

#include <tensorflow/lite/model.h>
#include <tensorflow/lite/interpreter.h>
#include <tensorflow/lite/kernels/register.h>
#include <tensorflow/lite/string_util.h>
#include <tensorflow/lite/interpreter_builder.h>
#include <tensorflow/lite/model_builder.h>

class TFLiteModel : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit TFLiteModel(QObject* parent = nullptr);
    TFLiteModel(const TFLiteModel& obj) = delete;

    static TFLiteModel* instancePtr;
    static TFLiteModel* instance();

    Q_INVOKABLE bool loadModel(const QString& modelPath);
    Q_INVOKABLE bool isMalicious(const QString& input);

    Q_PROPERTY(bool isModelLoaded READ isModelLoaded NOTIFY modelLoadedChanged)

    bool isModelLoaded() const { return m_isModelLoaded; }

signals:
    void modelLoadedChanged();
    void modelLoadingFailed(); 

private:
    std::unique_ptr<tflite::FlatBufferModel> model;
    std::unique_ptr<tflite::Interpreter> interpreter;
    bool m_isModelLoaded = false;

    float runInference(const QString& input);
};

#endif // TFLITEMODEL_H
