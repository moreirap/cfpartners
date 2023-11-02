FROM python:3

# Custom cache invalidation
ARG CACHEBUST=1

RUN mkdir /home/rates

WORKDIR /home/rates

COPY . ./

RUN pip install -Ur requirements.txt

EXPOSE 3000

ENTRYPOINT ["gunicorn", "--bind", ":3000", "wsgi"]