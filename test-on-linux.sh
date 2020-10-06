docker build -t test -f test.dockerfile . --no-cache
export BUILD_TYPE=DEV
docker run --env BUILD_TYPE test
