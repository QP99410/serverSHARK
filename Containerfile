# 1. Use 3.7 to maintain compatibility with older plugins
FROM python:3.7-bullseye

# 2. Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    git \
    libssl-dev \
    build-essential \
    default-libmysqlclient-dev \
    pkg-config \
    libgit2-dev \
    cmake \
    libmariadb-dev \
    python3-dev \
    maven \
    rsync \
    wget \
    ca-certificates \
    openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*


# FORCE JAVA 17 PRIORITY OVER JAVA 11 BY SYMLINKING INTO USR/LOCAL/BIN
RUN ln -sf /usr/lib/jvm/java-17-openjdk-amd64/bin/java /usr/local/bin/java && \
    ln -sf /usr/lib/jvm/java-17-openjdk-amd64/bin/javac /usr/local/bin/javac && \
    ln -sf /usr/lib/jvm/java-17-openjdk-amd64/bin/jar /usr/local/bin/jar

# 3. Build the exact libgit2 v0.26 from source to satisfy pygit2
RUN wget https://github.com/libgit2/libgit2/archive/v0.26.0.tar.gz && \
    tar xzf v0.26.0.tar.gz && \
    cd libgit2-0.26.0 && \
    cmake . && make && make install && \
    ldconfig && \
    cd .. && rm -rf libgit2-0.26.0 v0.26.0.tar.gz


WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip setuptools wheel pybind11 "pandas<2.0.0" "scikit-learn<1.2.0" "numpy<1.24.0" "scipy<1.10.0"

# Install modern pygit2 for Bullseye compatibility
RUN pip install --no-cache-dir pygit2 && \
    pip install --no-cache-dir -r requirements.txt

# 6. Pre-install the specific tools the plugins required
RUN pip install --no-cache-dir wheel cffi javalang beautifulsoup4

COPY . .

ENV DJANGO_SETTINGS_MODULE=server.settings
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
EXPOSE 8000

CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]