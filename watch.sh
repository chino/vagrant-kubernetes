watch -n 1 '
	      kubectl get pods --show-labels=true -o wide
	echo; kubectl get services -o wide | grep -v kubernetes
	echo; kubectl get ep | grep -v kubernetes
	echo; kubectl get ds
	echo; kubectl get nodes

	echo
	echo ========= all namespaces =========

	echo; kubectl get pods --show-labels=true -o wide --all-namespaces
	echo; kubectl get services -o wide --all-namespaces | grep -v kubernetes
	echo; kubectl get ep --all-namespaces | grep -v kubernetes
	echo; kubectl get ds --all-namespaces
'
