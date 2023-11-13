docker run -i --rm quay.io/coreos/butane:release --pretty --strict < leader.yaml   > k1.json
docker run -i --rm quay.io/coreos/butane:release --pretty --strict < follower.yaml > k2.json
docker run -i --rm quay.io/coreos/butane:release --pretty --strict < follower.yaml > k3.json
docker run -i --rm quay.io/coreos/butane:release --pretty --strict < follower.yaml > k4.json
