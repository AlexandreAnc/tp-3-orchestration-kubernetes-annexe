# TP Kubernetes — Application multi-services
# Usage : make <cible>
# Pour accéder au frontend / Mongo Express : lancer les port-forward dans des terminaux séparés (voir README).

NAMESPACE := tp-k8s
K8S_DIR  := k8s

.PHONY: build build-backend build-frontend deploy up expose-frontend expose-mongo-express restart status logs-backend logs-frontend delete delete-volumes help

start:
	minikube start

stop:
	minikube stop

# ——— Build (images dans le Docker de Minikube) ———
build: build-backend build-frontend

build-backend:
	eval $$(minikube docker-env) && docker build -t tp-k8s-backend:latest ./backend

build-frontend:
	eval $$(minikube docker-env) && docker build -t tp-k8s-frontend:latest ./frontend

# ——— Deploy ———
deploy:
	minikube kubectl -- apply -k $(K8S_DIR)/

# Build + deploy
up: build deploy
	@echo "Pods en cours de démarrage. Vérifier avec: make status"
	@echo "Pour ouvrir les services dans le navigateur: make expose-frontend et/ou make expose-mongo-express"

# ——— Exposition des services (ouverture via Minikube) ———
expose-frontend:
	minikube service frontend-service -n $(NAMESPACE)

expose-mongo-express:
	minikube service mongo-express -n $(NAMESPACE)

# Redémarrer backend et frontend (utile après rebuild d’images)
restart:
	minikube kubectl -- rollout restart deployment backend frontend -n $(NAMESPACE)

# ——— Status / Logs ———
status:
	@echo "=== Pods ==="
	minikube kubectl -- get pods -n $(NAMESPACE)
	@echo ""
	@echo "=== Services ==="
	minikube kubectl -- get svc -n $(NAMESPACE)

logs-backend:
	minikube kubectl -- logs -n $(NAMESPACE) -l app=backend -f

logs-frontend:
	minikube kubectl -- logs -n $(NAMESPACE) -l app=frontend -f

# ——— Nettoyage ———
delete:
	minikube kubectl -- delete -k $(K8S_DIR)/ --ignore-not-found || true

# Supprime aussi le PVC et le(s) PV associé(s) (données MongoDB perdues)
delete-volumes: delete
	# Supprime le PVC MongoDB
	minikube kubectl -- delete pvc mongodb-pvc -n $(NAMESPACE) --ignore-not-found || true
	# Supprime les PV liés à ce PVC (destructif)
	minikube kubectl -- delete pv $$(minikube kubectl -- get pv -o jsonpath='{range .items[?(@.spec.claimRef.name=="mongodb-pvc")]}{.metadata.name}{" "}{end}') --ignore-not-found || true

# ——— Aide ———
help:
	@echo "TP Kubernetes — cibles disponibles:"
	@echo "  make start          - Démarrer Minikube"
	@echo "  make build          - Construire les images backend et frontend dans le Docker de Minikube"
	@echo "  make deploy         - Déployer les manifests (minikube kubectl -- apply -k k8s/)"
	@echo "  make up             - build + deploy (équivalent à make build puis make deploy)"
	@echo "  make expose-frontend        - Ouvrir le frontend via minikube service"
	@echo "  make expose-mongo-express   - Ouvrir Mongo Express via minikube service"
	@echo "  make restart        - Redémarrer les déploiements backend et frontend"
	@echo "  make status         - Afficher pods et services"
	@echo "  make logs-backend   - Suivre les logs du backend"
	@echo "  make logs-frontend  - Suivre les logs du frontend"
	@echo "  make delete         - Supprimer les ressources du namespace"
	@echo "  make delete-volumes - delete + suppression du PVC (données MongoDB effacées)"
	@echo ""

