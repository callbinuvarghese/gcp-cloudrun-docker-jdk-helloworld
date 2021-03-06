This is a regular Spring Boot application using Tomcat server.

## Build
```
mvn package
```

## Run
```
java -jar target/helloworld.jar
```

## Containerize with Jib
```
mvn compile com.google.cloud.tools:jib-maven-plugin:2.4.0:build -Dimage=gcr.io/PROJECT_ID/helloworld-springboot-tomcat-jib
```

## Docker Build 
```
mvn package
docker build -t gcr.io/PROJECT_ID/helloworld-springboot-tomcat-appcds .
```

Run without AppCDS:
```
docker run -ti --rm gcr.io/PROJECT_ID/helloworld-springboot-tomcat-appcds
```

## App Engine

```
gcloud app deploy target/helloworld.jar
```

## Cloud Run
Run with Jib
```
gcloud run deploy helloworld-springboot-tomcat-jib \
  --image=gcr.io/PROJECT_ID/helloworld-springboot-tomcat-jib \
   --region=us-central1 \
   --platform managed \
   --allow-unauthenticated
```

Run with Docker Image, without AppCDS
```
gcloud run deploy helloworld-springboot-tomcat-docker \
  --image=gcr.io/PROJECT_ID/helloworld-springboot-tomcat \
  --region=us-central1 \
  --platform managed \
  --allow-unauthenticated
```

Run with Docker Image, without AppCDS, with Tiered compilation
```
gcloud run deploy helloworld-springboot-tomcat-docker-t1 \
  --image=gcr.io/PROJECT_ID/helloworld-springboot-tomcat \
  -e JAVA_TOOL_OPTIONS="-XX:+TieredCompilation -XX:TieredStopAtLevel=1"
  --region=us-central1 \
  --platform managed \
  --allow-unauthenticated
```



#Deploying Docket Container images on Google Cloud Artifact Registry
##===================================================================
###To deploy to Cloud Run, you must have the 

###    Owner or Editor role, 
###    or both the Cloud Run Admin and Service Account User roles, 
###    or any custom role that includes a specific set of permissions.


### Make sure the artifactregistry service is turnned on
#➜  gcloud services enable containerregistry.googleapis.com
➜  gcloud services list --enabled | grep 'registry'

artifactregistry.googleapis.com                                              Artifact Registry API
containerregistry.googleapis.com                                             Container Registry API

### List the repositories on the service
➜  gcloud beta artifacts repositories list
Listing items under projectPROJECT__ID, across alllocations
ARTIFACT_REGISTRY REPOSITORY FORMAT  DESCRIPTION                       LOCATION
LABELS                                                                                                                                                                                    ENCRYPTION          CREATE_TIME          UPDATE_TIME          SIZE (MB)

### Create a new repository with Docker format
➜ gcloud artifacts repositories create quickstart-docker-repo --repository-format=docker \
--location=us-east4 --description="Docker repository"
Create request issued for: [quickstart-docker-repo]
Waiting for operation [projects/PROJECT__ID/locations/us-east4/oper
ations/779ffb8b-7459-4171-bdcc-8984d819e87f] to complete...done.
Created repository [quickstart-docker-repo].

### List the repositories on the service to verify the create
➜  gcloud artifacts repositories list | grep 'quickstart-docker-repo'
Listing items under projectPROJECT__ID, across all locations.
ARTIFACT_REGISTRY REPOSITORY                        FORMAT  DESCRIPTION                       
LOCATION       LABELS                                                                                                                                                                                ENCRYPTION          CREATE_TIME          UPDATE_TIME          SIZE (MB)

quickstart-docker-repo                               DOCKER  Docker repository                 us-east4                                                                                                                                                                                                     Google-managed key  2022-04-26T23:48:06  2022-04-26T23:48:06  0

### Configure authentication to GCP for Docker
➜ gcloud auth configure-docker us-east4-docker.pkg.dev
WARNING: Your config file at [/Users/binu.b.varghese/.docker/config.json] contains these credential helper entries:

{
  "credHelpers": {
    "asia.gcr.io": "gcr",
    "eu.gcr.io": "gcr",
    "gcr.io": "gcr",
    "marketplace.gcr.io": "gcloud",
    "staging-k8s.gcr.io": "gcr",
    "us-east4-docker.pkg.dev": "gcloud",
    "us.gcr.io": "gcr"
  }
}
Adding credentials for: us-east4-docker.pkg.dev
gcloud credential helpers already registered correctly.

## Create a Java Springboot project ; Copying the java project from an existing project from the following location
➜  git clone https://github.com/saturnism/jvm-helloworld-by-example.git
➜  cd jvm-helloworld-by-example
➜  cp -r helloworld-springboot-tomcat ..
➜  cd ../helloworld-springboot-tomcat  

### Build the project

➜  mvn clean
➜  mvn package

### Test running the project
➜  java -Dserver.port=8087 -jar target/helloworld.jar

### List the repositories on the service
curl http://localhost:8087

### Build the project and tag it in the local docker registry
### ➜  docker build -t ${LOCATION}-docker.pkg.dev/$(PROJECT)/${REPO_WITH_DOCKER_FORMAT}/${IMAGE}:${VERSION} .

➜  docker build -t us-east4-docker.pkg.dev/PROJECT__ID/quickstart-docker-repo/helloworld-springboot-tomcat .
Sending build context to Docker daemon   16.5MB
Step 1/3 : FROM adoptopenjdk:8-jre-hotspot
 ---> f2e1db8c9bd9
Step 2/3 : COPY target/helloworld.jar /helloworld.jar
 ---> Using cache
 ---> 4dcb8dfb5f16
Step 3/3 : ENTRYPOINT java -jar helloworld.jar
 ---> Using cache
 ---> 0cbd55d53881
Successfully built 0cbd55d53881
Successfully tagged us-east4-docker.pkg.dev/PROJECT__ID/quickstart-docker-repo/helloworld-springboot-tomcat:latest

### Push the image to the GCP artifactregistry into an existing docker format repository
### ➜  docker push ${LOCATION}-docker.pkg.dev/$(PROJECT)/${REPO_WITH_DOCKER_FORMAT}/${IMAGE}:${VERSION}

➜  docker push us-east4-docker.pkg.dev/PROJECT__ID/quickstart-docker-repo/helloworld-springboot-tomcat:latest
The push refers to repository [us-east4-docker.pkg.dev/PROJECT__ID/quickstart-docker-repo/helloworld-springboot-tomcat]
d4bafc1bbfed: Pushed
15bbc04e2cf6: Pushed
14fbd8039ba4: Pushed
da55b45d310b: Pushed
latest: digest: sha256:32b7749bf5cc92bfb2aa21d269b6349f95f0163646a8c64786a4788537930c07 size: 1165

### verify that the image is in the remote GCP registry under the repository
➜  gcloud artifacts packages list --repository=quickstart-docker-repo --location=us-east4
Listing items under projectPROJECT__ID, location us-east4, repository quickstart-docker-repo.

PACKAGE                       CREATE_TIME          UPDATE_TIME
helloworld-springboot-tomcat  2022-04-27T00:01:02  2022-04-27T00:01:02

### Update Description of the repository
➜ gcloud artifacts repositories update quickstart-docker-repo --location="us-east4" --description="Test Repository for Docker Images for TESTPROJ"

Updated repository [quickstart-docker-repo].
createTime: '2022-04-27T03:48:06.209242Z'
description: Test Repository for Docker Images for TESTPROJ
format: DOCKER
mavenConfig: {}
name: projects/PROJECT__ID/locations/us-east4/repositories/quickstart-docker-repo
updateTime: '2022-04-28T01:26:53.601808Z'

### Check the Description of the repository
➜  gcloud artifacts repositories describe quickstart-docker-repo --location=us-east4
Encryption: Google-managed key
Repository Size: 0.000MB
createTime: '2022-04-27T03:48:06.209242Z'
description: Test Repository for Docker Images for TESTPROJ
format: DOCKER
mavenConfig: {}
name: projects/PROJECT__ID/locations/us-east4/repositories/quickstart-docker-repo
updateTime: '2022-04-28T01:26:53.601808Z'
➜

### The following screen on the GCP console shows the registry and repositories
https://console.cloud.google.com/artifacts?referrer=search&project=PROJECT

### You can pull the image from the repo as follows, if you may
docker pull \
    us-east4-docker.pkg.dev/PROJECT/quickstart-docker-repo/helloworld-springboot-tomcat:latest

## Deploy the image to GCP Cloud Run
### Permissions needed for user role
https://cloud.google.com/run/docs/deploying
Permissions required to deploy
You must have ONE of the following:

Owner
Editor
Both the Cloud Run Admin and Service Account User roles
Any custom role that includes this specific list of permissions


gcloud run deploy SERVICE --image \
REPO-LOCATION-docker.pkg.dev/PROJECT-ID/IMAGE \
[--platform managed --region RUN-REGION]

 cloud run deploy helloworld-springboot-tomcat-svc --image \
us-east4-docker.pkg.dev/PROJECT/quickstart-docker-repo/helloworld-springboot-tomcat:latest \
--platform managed --region us-east4

➜  gcloud run deploy helloworld-springboot-tomcat-svc --image \
us-east4-docker.pkg.dev/PROJECT/quickstart-docker-repo/helloworld-springboot-tomcat:latest \
--platform managed --region us-east4
Deploying container to Cloud Run service [helloworld-springboot-tomcat-svc] in project [PROJECT] region [us-east4]
✓ Deploying... Done.
  ✓ Creating Revision... Revision deployment finished. Checking container healt
  h.
  ✓ Routing traffic...
Done.
Service [helloworld-springboot-tomcat-svc] revision [helloworld-springboot-tomcat-svc-00002-kub] has been deployed and is serving 100 percent of traffic.
Service URL: https://helloworld-springboot-tomcat-svc-vtyatvjjvq-uk.a.run.app

➜  curl https://helloworld-springboot-tomcat-svc-vtyatvjjvq-uk.a.run.app

<html><head>
<meta http-equiv="content-type" content="text/html;charset=utf-8">
<title>403 Forbidden</title>
</head>
<body text=#000000 bgcolor=#ffffff>
<h1>Error: Forbidden</h1>
<h2>Your client does not have permission to get URL <code>/</code> from this server.</h2>
<h2></h2>
</b

### By default you do not have permission to access the URL. You have to access it with your identity token as the Bearer token for OAuth authentication
### test you can access your ID token
➜    gcloud auth print-identity-token
xxxx.yyyyy.zzz


### Access it with ID token as Bearer Token; you get the helloworld output
➜  curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" https://helloworld-springboot-tomcat-svc-vtyatvjjvq-uk.a.run.app
Hello World!%

