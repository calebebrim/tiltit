







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