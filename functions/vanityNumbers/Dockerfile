FROM amazon/aws-lambda-python:3.9

# Copy function code
COPY index.py ${LAMBDA_TASK_ROOT}

# Install the function's dependencies using file requirements.txt
# from your project folder.

COPY requirements.txt  .
RUN  pip install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"
# RUN python -m nltk.downloader -d ${LAMBDA_TASK_ROOT}/nltk_data wordnet2021
RUN python -m nltk.downloader wordnet2021 -d ${LAMBDA_TASK_ROOT}/nltk_data
#RUN [ "python3", "-c", "import nltk; nltk.download('wordnet2021', download_dir='${LAMBDA_TASK_ROOT}/nltk_data')" ]

# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
CMD [ "index.lambda_handler" ] 