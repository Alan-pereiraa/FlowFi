# cirruslabs has not published a 3.47.x tag yet (stable = 3.44.0, Dart 3.12),
# but pubspec requires Dart ^3.13.1. The image's SDK is a git checkout, so pin
# the exact Flutter version by checking out its tag and re-warming the
# toolchain. Keep this in sync with the Flutter version used locally.
FROM ghcr.io/cirruslabs/flutter:stable

RUN cd /sdks/flutter \
    && git fetch --depth 1 origin refs/tags/3.47.1:refs/tags/3.47.1 \
    && git checkout 3.47.1 \
    && flutter --version \
    && flutter precache --web

WORKDIR /app

EXPOSE 5000
