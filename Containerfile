# 1. Use 3.8 to maintain compatibility with older plugins
FROM python:3.8-bullseye

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
    && rm -rf /var/lib/apt/lists/*

# 3. Build the exact libgit2 v0.26 from source to satisfy pygit2
RUN apt-get install -y wget && \
    wget https://github.com/libgit2/libgit2/archive/v0.26.0.tar.gz && \
    tar xzf v0.26.0.tar.gz && \
    cd libgit2-0.26.0 && \
    cmake . && make && make install && \
    ldconfig && \
    cd .. && rm -rf libgit2-0.26.0 v0.26.0.tar.gz

# 4. Create a symlink so if a script calls 'python3.5' or 'pip3.5', 
# it uses the container's python 3.8 instead of failing.
RUN ln -s /usr/local/bin/python /usr/local/bin/python3.5 && \
    ln -s /usr/local/bin/pip /usr/local/bin/pip3.5

WORKDIR /app

# 5. Install base requirements
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip setuptools wheel pybind11 "pandas<2.0.0" "scikit-learn<1.2.0" "numpy<1.24.0" "scipy<1.10.0"

# Install modern pygit2 for Bullseye compatibility
RUN sed -i '/pygit2/d' requirements.txt && \
    pip install --no-cache-dir pygit2 && \
    pip install --no-cache-dir -r requirements.txt

# 6. Pre-install the specific tools the plugins required
RUN pip install --no-cache-dir wheel cffi

COPY . .

ENV DJANGO_SETTINGS_MODULE=server.settings
EXPOSE 8000

CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]