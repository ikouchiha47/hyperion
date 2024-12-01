prepare:
	python3 train.py

release: prepare
	mkdir -p ../thparty/include/mlmodels && cp ./phishing_detection.tflite ../thparty/include/mlmodels/
