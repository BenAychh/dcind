# dcind (Docker-Compose-in-Docker)

Forked from the excellent work my meAmidos at https://github.com/meAmidos/dcind

Big changes here is that the docker file is now based on `docker:dind` and the startup docker-lib.sh startup script has a different way of starting the docker daemon based on the concourse docker-image-resource here: https://github.com/concourse/docker-image-resource/blob/master/assets/common.sh#L64

Use this ```Dockerfile``` to build a base image for your integration tests in [Concourse CI](http://concourse.ci/). Alternatively, you can use a ready-to-use image from Docker Hub: [benaychh/concourse-dcind](https://hub.docker.com/u/benaychh/concourse-dcind/).

Here is an example of Concourse [job](http://concourse.ci/concepts.html) that uses ```benaychh/concourse-dcind``` image to run a bunch of containers in a task, and then runs the integration test suite.

```yaml
  - name: integration
    plan:
      - aggregate:
        - get: code
          params: {depth: 1}
          passed: [unit-tests]
          trigger: true
        - get: redis
          params: {save: true}
        - get: busybox
          params: {save: true}
      - task: Run integration tests
        privileged: true
        config:
          platform: linux
          image_resource:
            type: docker-image
            source:
              repository: benaychh/concourse-dcind
          inputs:
            - name: code
            - name: redis
            - name: busybox
          run:
            path: sh
            args:
              - -exc
              - |
                source /docker-lib.sh
                start_docker

                # Strictly speaking, preloading of images is not required.
                # However you might want to do it for a couple of reasons:
                # - If the image is from a private repository, it is much easier to let concourse pull it,
                #   and then pass it through to the task.
                # - When the image is passed to the task, Concourse can often get the image from its cache.
                docker load -i redis/image
                docker tag "$(cat redis/image-id)" "$(cat redis/repository):$(cat redis/tag)"

                docker load -i busybox/image
                docker tag "$(cat busybox/image-id)" "$(cat busybox/repository):$(cat busybox/tag)"

                # This is just to visually check in the log that images have been loaded successfully
                docker images

                # Run the tests container and its dependencies.
                docker-compose -f code/example/integration.yml run tests


```
