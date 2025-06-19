def kafka_storage_yaml(name, storage_class_name="kafka-storage", path="/data/kafkastorage", node_affinity=['worker']):
  affinity = "\n          - ".join([""]+node_affinity)  
  return blob("""
apiVersion: v1
kind: PersistentVolume
metadata:
  name: {name}-storage
spec:
  capacity:
    storage: 100Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  storageClassName: {storage_class_name}
  local:
    path: {path}
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values: {affinity}

""".format(
  name=name, 
  storage_class_name=storage_class_name, 
  path=path,
  affinity=affinity
  ))


def kafka_yaml(name='kafka', storage_class_name="kafka-storage", replicas=1, debugger=False):
  tmp = """
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaNodePool
metadata:
  name: {name}-nodepool
  labels:
    strimzi.io/cluster: {name}-cluster
spec:
  replicas: {replicas}
  roles:
    - controller
    - broker
  storage:
    type: jbod
    volumes:
      - id: 0
        type: persistent-claim
        size: 100Gi
        class: {storage_class_name} # Storage class for Kafka
        deleteClaim: false
        kraftMetadata: shared
  resources:
    requests:
      memory: 2Gi
      cpu: 500m
    limits:
      memory: 4Gi
      cpu: 1
---

apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: {name}-cluster
  annotations:
    strimzi.io/node-pools: enabled
    strimzi.io/kraft: enabled
spec:
  kafka:
    version: 4.0.0
    metadataVersion: 4.0-IV3
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
      - name: tls
        port: 9093
        type: internal
        tls: true
    config:
      offsets.topic.replication.factor: 1
      transaction.state.log.replication.factor: 1
      transaction.state.log.min.isr: 1
      default.replication.factor: 1
      min.insync.replicas: 1
  entityOperator:
    topicOperator:
      resources:
        requests:
          memory: 256Mi
          cpu: 100m
        limits:
          memory: 512Mi
          cpu: 200m
    userOperator:
      resources:
        requests:
          memory: 256Mi
          cpu: 100m
        limits:
          memory: 512Mi
          cpu: 200m
  """.format(
    name=name, 
    storage_class_name=storage_class_name,
    replicas=replicas)
  if debugger:
    print(tmp)
  return blob(tmp)


POSTGRE_YAML = blob("""
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:16
          ports:
            - containerPort: 5432
          env:
            - name: POSTGRES_DB
              value: mydatabase
            - name: POSTGRES_USER
              value: myuser
            - name: POSTGRES_PASSWORD
              value: mypassword
          volumeMounts:
            - name: postgres-data
              mountPath: /var/lib/postgresql/data
      volumes:
        - name: postgres-data
          emptyDir: {}

---
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  type: ClusterIP
  selector:
    app: postgres
  ports:
    - port: 5432
      targetPort: 5432
""")

REDIS_YAML=blob("""
apiVersion: v1
kind: ConfigMap
metadata:
  name: redis-config
data:
  redis.conf: |
    # Redis configuration
    user default on >yourStrongPassword allkeys allcommands
    # Optional: additional Redis configurations
    protected-mode yes
    port 6379
    # Enable AOF for durability
    appendonly yes
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  labels:
    app: redis
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
        - name: redis
          image: redis/redis-stack:7.4.0-v5
          env:
            - name: REDIS_PASSWORD
              value: "yourStrongPassword"
            - name: REDIS_ARGS
              value: "--protected-mode no"
          ports:
            - name: "redis" 
              containerPort: 6379
            - name: "http"
              containerPort: 8001
          livenessProbe:
            tcpSocket:
              port: 6379
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            tcpSocket:
              port: 6379
            initialDelaySeconds: 5
            periodSeconds: 10
          resources:
            requests:
              memory: "256Mi"
              cpu: "250m"
            limits:
              memory: "1Gi"
              cpu: "500m"
          volumeMounts:
            - name: redis-data
              mountPath: /data
            # - name: redis-config
            #   mountPath: /usr/local/etc/redis/redis.conf
            #   subPath: redis.conf
          # command:
          #   - "redis-server"
          #   - "--appendonly"
          #   - "yes"
      volumes:
        - name: redis-data
          emptyDir: {}
        # - name: redis-config
        #   configMap:
        #     name: redis-config
---
apiVersion: v1
kind: Service
metadata:
  name: redis
spec:
  type: ClusterIP
  ports:
    - name: "redis"
      port: 6379
      targetPort: 6379
    - port: 8001
      targetPort: 8001
      name: "http"
  selector:
    app: redis
""")


MINIO_YAML=blob("""
apiVersion: v1
kind: PersistentVolume
metadata:
  name: minio-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  local:
    path: /data/storage/minio
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - fireplace-worker
          - fireplace-worker2
          - fireplace-control-plane
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: minio-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: manual
  resources:
    requests:
      storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minio
spec:
  replicas: 1
  selector:
    matchLabels:
      app: minio
  template:
    metadata:
      labels:
        app: minio
    spec:
      containers:
        - name: minio
          image: quay.io/minio/minio:latest
          args:
            - server
            - /data
            - --console-address
            - ":9001"
          env:
            - name: MINIO_ROOT_USER
              value: minioadmin
            - name: MINIO_ROOT_PASSWORD
              value: minioadmin
          ports:
            - containerPort: 9000
            - containerPort: 9001
          volumeMounts:
            - name: storage
              mountPath: /data
      volumes:
        - name: storage
          persistentVolumeClaim:
            claimName: minio-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: minio-service
spec:
  type: ClusterIP
  ports:
    - port: 9000
      targetPort: 9000
      name: api
    - port: 9001
      targetPort: 9001
      name: console
  selector:
    app: minio

""")


SUPERSET_YAML = blob("""
apiVersion: apps/v1
kind: Deployment
metadata:
  name: superset
  labels:
    app: superset
spec:
  replicas: 1
  selector:
    matchLabels:
      app: superset
  template:
    metadata:
      labels:
        app: superset
    spec:
      containers:
        - name: superset
          image: apache/superset:3.0.0
          ports:
            - containerPort: 8088
          env:
            - name: SUPERSET_ENV
              value: development
            - name: SUPERSET_LOAD_EXAMPLES
              value: "no"
            - name: SUPERSET_DATABASE_URI
              value: postgresql+psycopg2://myuser:mypassword@postgres:5432/mydatabase
          resources:
            requests:
              cpu: "250m"
              memory: "512Mi"
            limits:
              cpu: "500m"
              memory: "1Gi"
          volumeMounts:
            - name: superset-config
              mountPath: /app/pythonpath
      initContainers:
        - name: superset-init
          image: apache/superset:3.0.0
          # for development purposes, initialize the database and create an admin user here. 
          command:
            - /bin/bash
            - -c
            - |
              superset db upgrade
              if ! superset fab list-users | grep -q admin; then
                echo "Admin user not found. Creating..."
                superset fab create-admin \
                  --username admin \
                  --firstname Superset \
                  --lastname Admin \
                  --email admin@superset.com \
                  --password admin
              else
                echo "Admin user already exists. Skipping creation."
              fi
              superset init
              superset run -p 8088 --with-threads --reload --debugger
          env:
            - name: SUPERSET_ENV
              value: production
            - name: SUPERSET_DATABASE_URI
              value: postgresql+psycopg2://myuser:mypassword@postgres:5432/mydatabase
            - name: SUPERSET_SECRET_KEY
              value: "k8s8f3j2l1p9q6z7x4v0b5w2r8t3s6y1d"
            - name: RATELIMIT_STORAGE_URL
              value: "redis://redis:6379/8"
            - name: SUPERSET_PORT
              value: "8088"
      volumes:
        - name: superset-config
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: superset
spec:
  type: ClusterIP
  selector:
    app: superset
  ports:
    - port: 8088
      targetPort: 8088

""")