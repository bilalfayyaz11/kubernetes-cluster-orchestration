# Kubernetes Autoscaling Validation Report

## Environment

- Cluster type: kind
- Kubernetes context: kind-autoscaling
- Worker implementation: Docker containers
- Intended minimum worker count: 2
- Intended maximum worker count: 5
- Scale-down utilization threshold: 0.5
- Scale-down unneeded time: 2 minutes
- Scale-down delay after node addition: 2 minutes
- Expander strategy: least-waste

## Baseline Node State

Snapshot: Baseline
Timestamp: 2026-07-16T16:11:25+00:00

===== NODES =====
NAME                        STATUS   ROLES           AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION            CONTAINER-RUNTIME
autoscaling-control-plane   Ready    control-plane   7m58s   v1.36.1   172.18.0.3    <none>        Debian GNU/Linux 13 (trixie)   6.14.0-1018-aws (amd64)   containerd://2.3.1
autoscaling-worker          Ready    <none>          7m46s   v1.36.1   172.18.0.2    <none>        Debian GNU/Linux 13 (trixie)   6.14.0-1018-aws (amd64)   containerd://2.3.1
autoscaling-worker2         Ready    <none>          7m45s   v1.36.1   172.18.0.4    <none>        Debian GNU/Linux 13 (trixie)   6.14.0-1018-aws (amd64)   containerd://2.3.1

===== NODE METRICS =====
NAME                        CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
autoscaling-control-plane   282m         7%       560Mi           3%          
autoscaling-worker          338m         8%       178Mi           1%          
autoscaling-worker2         46m          1%       141Mi           0%          

===== PROTECTED POD =====
NAME                                 READY   STATUS    RESTARTS   AGE   IP           NODE                 NOMINATED NODE   READINESS GATES
protected-service-67fd8f9848-99ffc   1/1     Running   0          25s   10.244.1.6   autoscaling-worker   <none>           <none>

===== POD DISRUPTION BUDGET =====
NAME                    MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
protected-service-pdb   1               N/A               0                     25s

## Post Scale-Up Demand State

Snapshot: Post Scale-Up Demand
Timestamp: 2026-07-16T16:12:10+00:00

===== NODES =====
NAME                        STATUS   ROLES           AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION            CONTAINER-RUNTIME
autoscaling-control-plane   Ready    control-plane   8m43s   v1.36.1   172.18.0.3    <none>        Debian GNU/Linux 13 (trixie)   6.14.0-1018-aws (amd64)   containerd://2.3.1
autoscaling-worker          Ready    <none>          8m31s   v1.36.1   172.18.0.2    <none>        Debian GNU/Linux 13 (trixie)   6.14.0-1018-aws (amd64)   containerd://2.3.1
autoscaling-worker2         Ready    <none>          8m30s   v1.36.1   172.18.0.4    <none>        Debian GNU/Linux 13 (trixie)   6.14.0-1018-aws (amd64)   containerd://2.3.1

===== NODE METRICS =====
NAME                        CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
autoscaling-control-plane   469m         11%      560Mi           3%          
autoscaling-worker          246m         6%       190Mi           1%          
autoscaling-worker2         131m         3%       148Mi           0%          

===== WORKLOAD PODS =====
NAME                                   READY   STATUS    RESTARTS   AGE     IP           NODE                  NOMINATED NODE   READINESS GATES
scheduling-pressure-6bbf4ffcb4-2ww8l   1/1     Running   0          4m39s   10.244.2.5   autoscaling-worker2   <none>           <none>
scheduling-pressure-6bbf4ffcb4-858sv   1/1     Running   0          30s     10.244.2.6   autoscaling-worker2   <none>           <none>
scheduling-pressure-6bbf4ffcb4-8klv2   0/1     Pending   0          30s     <none>       <none>                <none>           <none>
scheduling-pressure-6bbf4ffcb4-9r49l   0/1     Pending   0          30s     <none>       <none>                <none>           <none>
scheduling-pressure-6bbf4ffcb4-c4jr6   1/1     Running   0          30s     10.244.1.8   autoscaling-worker    <none>           <none>
scheduling-pressure-6bbf4ffcb4-dgntx   1/1     Running   0          30s     10.244.1.9   autoscaling-worker    <none>           <none>
scheduling-pressure-6bbf4ffcb4-jrvjr   1/1     Running   0          30s     10.244.1.7   autoscaling-worker    <none>           <none>
scheduling-pressure-6bbf4ffcb4-lrw8r   0/1     Pending   0          30s     <none>       <none>                <none>           <none>
scheduling-pressure-6bbf4ffcb4-pmd24   0/1     Pending   0          30s     <none>       <none>                <none>           <none>
scheduling-pressure-6bbf4ffcb4-sxjqt   0/1     Pending   0          30s     <none>       <none>                <none>           <none>
scheduling-pressure-6bbf4ffcb4-vmxnb   1/1     Running   0          5m3s    10.244.2.3   autoscaling-worker2   <none>           <none>
scheduling-pressure-6bbf4ffcb4-w5vrv   0/1     Pending   0          30s     <none>       <none>                <none>           <none>

===== PENDING POD COUNT =====
6

===== FAILED SCHEDULING EVENTS =====
5m4s        Normal    SuccessfulCreate          replicaset/scheduling-pressure-6bbf4ffcb4   Created pod: scheduling-pressure-6bbf4ffcb4-vmxnb
5m4s        Normal    ScalingReplicaSet         deployment/scheduling-pressure              Scaled up replica set scheduling-pressure-6bbf4ffcb4 from 0 to 1
5m4s        Normal    Scheduled                 pod/scheduling-pressure-6bbf4ffcb4-vmxnb    Successfully assigned default/scheduling-pressure-6bbf4ffcb4-vmxnb to autoscaling-worker2
5m3s        Normal    Pulling                   pod/scheduling-pressure-6bbf4ffcb4-vmxnb    Pulling image "registry.k8s.io/pause:3.10.1"
5m3s        Normal    Pulled                    pod/scheduling-pressure-6bbf4ffcb4-vmxnb    Successfully pulled image "registry.k8s.io/pause:3.10.1" in 422ms (422ms including waiting). Image size: 320448 bytes.
5m3s        Normal    Created                   pod/scheduling-pressure-6bbf4ffcb4-vmxnb    Container created
5m3s        Normal    Started                   pod/scheduling-pressure-6bbf4ffcb4-vmxnb    Container started
4m40s       Normal    SuccessfulCreate          replicaset/scheduling-pressure-6bbf4ffcb4   Created pod: scheduling-pressure-6bbf4ffcb4-2ww8l
4m40s       Normal    Scheduled                 pod/scheduling-pressure-6bbf4ffcb4-xrcsp    Successfully assigned default/scheduling-pressure-6bbf4ffcb4-xrcsp to autoscaling-worker
4m40s       Normal    SuccessfulCreate          replicaset/scheduling-pressure-6bbf4ffcb4   Created pod: scheduling-pressure-6bbf4ffcb4-52lzd
4m40s       Normal    SuccessfulCreate          replicaset/scheduling-pressure-6bbf4ffcb4   Created pod: scheduling-pressure-6bbf4ffcb4-xrcsp
4m40s       Normal    SuccessfulCreate          replicaset/scheduling-pressure-6bbf4ffcb4   Created pod: scheduling-pressure-6bbf4ffcb4-dd7jk
4m40s       Normal    Scheduled                 pod/scheduling-pressure-6bbf4ffcb4-52lzd    Successfully assigned default/scheduling-pressure-6bbf4ffcb4-52lzd to autoscaling-worker
4m40s       Normal    ScalingReplicaSet         deployment/scheduling-pressure              Scaled up replica set scheduling-pressure-6bbf4ffcb4 from 1 to 8
4m40s       Normal    SuccessfulCreate          replicaset/scheduling-pressure-6bbf4ffcb4   Created pod: scheduling-pressure-6bbf4ffcb4-lzdqt
4m39s       Normal    Pulled                    pod/scheduling-pressure-6bbf4ffcb4-dd7jk    Container image "registry.k8s.io/pause:3.10.1" already present on machine and can be accessed by the pod
4m40s       Normal    SuccessfulCreate          replicaset/scheduling-pressure-6bbf4ffcb4   Created pod: scheduling-pressure-6bbf4ffcb4-9g448
4m39s       Normal    Created                   pod/scheduling-pressure-6bbf4ffcb4-2ww8l    Container created
4m39s       Normal    Started                   pod/scheduling-pressure-6bbf4ffcb4-2ww8l    Container started
4m39s       Normal    Pulling                   pod/scheduling-pressure-6bbf4ffcb4-52lzd    Pulling image "registry.k8s.io/pause:3.10.1"
4m40s       Warning   FailedScheduling          pod/scheduling-pressure-6bbf4ffcb4-f7jpl    0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient cpu. no new claims to deallocate, preemption: 0/3 nodes are available: 1 Preemption is not helpful for scheduling, 2 No preemption victims found for incoming pod.
4m40s       Normal    Scheduled                 pod/scheduling-pressure-6bbf4ffcb4-2ww8l    Successfully assigned default/scheduling-pressure-6bbf4ffcb4-2ww8l to autoscaling-worker2
4m39s       Normal    Pulling                   pod/scheduling-pressure-6bbf4ffcb4-xrcsp    Pulling image "registry.k8s.io/pause:3.10.1"
4m40s       Warning   FailedScheduling          pod/scheduling-pressure-6bbf4ffcb4-9g448    0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient cpu. no new claims to deallocate, preemption: 0/3 nodes are available: 1 Preemption is not helpful for scheduling, 2 No preemption victims found for incoming pod.
4m40s       Normal    Scheduled                 pod/scheduling-pressure-6bbf4ffcb4-lzdqt    Successfully assigned default/scheduling-pressure-6bbf4ffcb4-lzdqt to autoscaling-worker
4m40s       Normal    SuccessfulCreate          replicaset/scheduling-pressure-6bbf4ffcb4   Created pod: scheduling-pressure-6bbf4ffcb4-f7jpl
4m39s       Normal    Pulled                    pod/scheduling-pressure-6bbf4ffcb4-2ww8l    Container image "registry.k8s.io/pause:3.10.1" already present on machine and can be accessed by the pod
4m39s       Normal    Pulling                   pod/scheduling-pressure-6bbf4ffcb4-lzdqt    Pulling image "registry.k8s.io/pause:3.10.1"
4m39s       Normal    Started                   pod/scheduling-pressure-6bbf4ffcb4-dd7jk    Container started
4m40s       Normal    Scheduled                 pod/scheduling-pressure-6bbf4ffcb4-dd7jk    Successfully assigned default/scheduling-pressure-6bbf4ffcb4-dd7jk to autoscaling-worker2
4m39s       Normal    Created                   pod/scheduling-pressure-6bbf4ffcb4-dd7jk    Container created
4m38s       Normal    Created                   pod/scheduling-pressure-6bbf4ffcb4-52lzd    Container created
4m38s       Normal    Started                   pod/scheduling-pressure-6bbf4ffcb4-xrcsp    Container started
4m38s       Normal    Pulled                    pod/scheduling-pressure-6bbf4ffcb4-lzdqt    Successfully pulled image "registry.k8s.io/pause:3.10.1" in 115ms (513ms including waiting). Image size: 320448 bytes.
4m38s       Normal    Created                   pod/scheduling-pressure-6bbf4ffcb4-lzdqt    Container created
4m38s       Normal    Started                   pod/scheduling-pressure-6bbf4ffcb4-52lzd    Container started
4m38s       Normal    Started                   pod/scheduling-pressure-6bbf4ffcb4-lzdqt    Container started
4m38s       Normal    Pulled                    pod/scheduling-pressure-6bbf4ffcb4-xrcsp    Successfully pulled image "registry.k8s.io/pause:3.10.1" in 113ms (434ms including waiting). Image size: 320448 bytes.
4m38s       Normal    Pulled                    pod/scheduling-pressure-6bbf4ffcb4-52lzd    Successfully pulled image "registry.k8s.io/pause:3.10.1" in 515ms (515ms including waiting). Image size: 320448 bytes.
4m38s       Normal    Created                   pod/scheduling-pressure-6bbf4ffcb4-xrcsp    Container created
2m41s       Normal    SuccessfulDelete          replicaset/scheduling-pressure-6bbf4ffcb4   Deleted pod: scheduling-pressure-6bbf4ffcb4-52lzd
2m41s       Normal    SuccessfulDelete          replicaset/scheduling-pressure-6bbf4ffcb4   Deleted pod: scheduling-pressure-6bbf4ffcb4-9g448
2m41s       Normal    Killing                   pod/scheduling-pressure-6bbf4ffcb4-52lzd    Stopping container workload
2m41s       Normal    ScalingReplicaSet         deployment/scheduling-pressure              Scaled down replica set scheduling-pressure-6bbf4ffcb4 from 8 to 2
2m41s       Normal    SuccessfulDelete          replicaset/scheduling-pressure-6bbf4ffcb4   Deleted pod: scheduling-pressure-6bbf4ffcb4-f7jpl
2m41s       Normal    Killing                   pod/scheduling-pressure-6bbf4ffcb4-dd7jk    Stopping container workload
2m41s       Normal    SuccessfulDelete          replicaset/scheduling-pressure-6bbf4ffcb4   Deleted pod: scheduling-pressure-6bbf4ffcb4-lzdqt
2m41s       Normal    SuccessfulDelete          replicaset/scheduling-pressure-6bbf4ffcb4   Deleted pod: scheduling-pressure-6bbf4ffcb4-dd7jk
2m41s       Normal    SuccessfulDelete          replicaset/scheduling-pressure-6bbf4ffcb4   Deleted pod: scheduling-pressure-6bbf4ffcb4-xrcsp
2m41s       Normal    Killing                   pod/scheduling-pressure-6bbf4ffcb4-lzdqt    Stopping container workload
2m41s       Normal    Killing                   pod/scheduling-pressure-6bbf4ffcb4-xrcsp    Stopping container workload
31s         Warning   FailedScheduling          pod/scheduling-pressure-6bbf4ffcb4-9r49l    0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient cpu. no new claims to deallocate, preemption: 0/3 nodes are available: 1 Preemption is not helpful for scheduling, 2 No preemption victims found for incoming pod.
31s         Normal    Scheduled                 pod/scheduling-pressure-6bbf4ffcb4-c4jr6    Successfully assigned default/scheduling-pressure-6bbf4ffcb4-c4jr6 to autoscaling-worker
31s         Normal    ScalingReplicaSet         deployment/scheduling-pressure              Scaled up replica set scheduling-pressure-6bbf4ffcb4 from 2 to 12
31s         Normal    Scheduled                 pod/scheduling-pressure-6bbf4ffcb4-858sv    Successfully assigned default/scheduling-pressure-6bbf4ffcb4-858sv to autoscaling-worker2
31s         Normal    SuccessfulCreate          replicaset/scheduling-pressure-6bbf4ffcb4   (combined from similar events): Created pod: scheduling-pressure-6bbf4ffcb4-pmd24
31s         Normal    Scheduled                 pod/scheduling-pressure-6bbf4ffcb4-jrvjr    Successfully assigned default/scheduling-pressure-6bbf4ffcb4-jrvjr to autoscaling-worker
31s         Normal    SuccessfulCreate          replicaset/scheduling-pressure-6bbf4ffcb4   Created pod: scheduling-pressure-6bbf4ffcb4-jrvjr
31s         Warning   FailedScheduling          pod/scheduling-pressure-6bbf4ffcb4-8klv2    0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient cpu. no new claims to deallocate, preemption: 0/3 nodes are available: 1 Preemption is not helpful for scheduling, 2 No preemption victims found for incoming pod.
31s         Warning   FailedScheduling          pod/scheduling-pressure-6bbf4ffcb4-pmd24    0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient cpu. no new claims to deallocate, preemption: 0/3 nodes are available: 1 Preemption is not helpful for scheduling, 2 No preemption victims found for incoming pod.
31s         Warning   FailedScheduling          pod/scheduling-pressure-6bbf4ffcb4-w5vrv    0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient cpu. no new claims to deallocate, preemption: 0/3 nodes are available: 1 Preemption is not helpful for scheduling, 2 No preemption victims found for incoming pod.
31s         Warning   FailedScheduling          pod/scheduling-pressure-6bbf4ffcb4-sxjqt    0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient cpu. no new claims to deallocate, preemption: 0/3 nodes are available: 1 Preemption is not helpful for scheduling, 2 No preemption victims found for incoming pod.
31s         Normal    Scheduled                 pod/scheduling-pressure-6bbf4ffcb4-dgntx    Successfully assigned default/scheduling-pressure-6bbf4ffcb4-dgntx to autoscaling-worker
31s         Warning   FailedScheduling          pod/scheduling-pressure-6bbf4ffcb4-lrw8r    0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient cpu. no new claims to deallocate, preemption: 0/3 nodes are available: 1 Preemption is not helpful for scheduling, 2 No preemption victims found for incoming pod.
30s         Normal    Created                   pod/scheduling-pressure-6bbf4ffcb4-dgntx    Container created
30s         Normal    Started                   pod/scheduling-pressure-6bbf4ffcb4-c4jr6    Container started
30s         Normal    Created                   pod/scheduling-pressure-6bbf4ffcb4-858sv    Container created
30s         Normal    Pulled                    pod/scheduling-pressure-6bbf4ffcb4-dgntx    Container image "registry.k8s.io/pause:3.10.1" already present on machine and can be accessed by the pod
30s         Normal    Pulled                    pod/scheduling-pressure-6bbf4ffcb4-c4jr6    Container image "registry.k8s.io/pause:3.10.1" already present on machine and can be accessed by the pod
30s         Normal    Started                   pod/scheduling-pressure-6bbf4ffcb4-858sv    Container started
30s         Normal    Started                   pod/scheduling-pressure-6bbf4ffcb4-dgntx    Container started
30s         Normal    Pulled                    pod/scheduling-pressure-6bbf4ffcb4-jrvjr    Container image "registry.k8s.io/pause:3.10.1" already present on machine and can be accessed by the pod
30s         Normal    Created                   pod/scheduling-pressure-6bbf4ffcb4-c4jr6    Container created
30s         Normal    Pulled                    pod/scheduling-pressure-6bbf4ffcb4-858sv    Container image "registry.k8s.io/pause:3.10.1" already present on machine and can be accessed by the pod
30s         Normal    Created                   pod/scheduling-pressure-6bbf4ffcb4-jrvjr    Container created
30s         Normal    Started                   pod/scheduling-pressure-6bbf4ffcb4-jrvjr    Container started

## Post Scale-Down Attempt State

Snapshot: Post Scale-Down Attempt
Timestamp: 2026-07-16T16:14:56+00:00

===== NODES =====
NAME                        STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION            CONTAINER-RUNTIME
autoscaling-control-plane   Ready    control-plane   11m   v1.36.1   172.18.0.3    <none>        Debian GNU/Linux 13 (trixie)   6.14.0-1018-aws (amd64)   containerd://2.3.1
autoscaling-worker          Ready    <none>          11m   v1.36.1   172.18.0.2    <none>        Debian GNU/Linux 13 (trixie)   6.14.0-1018-aws (amd64)   containerd://2.3.1
autoscaling-worker2         Ready    <none>          11m   v1.36.1   172.18.0.4    <none>        Debian GNU/Linux 13 (trixie)   6.14.0-1018-aws (amd64)   containerd://2.3.1

===== NODE METRICS =====
NAME                        CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
autoscaling-control-plane   241m         6%       573Mi           3%          
autoscaling-worker          105m         2%       148Mi           0%          
autoscaling-worker2         76m          1%       164Mi           1%          

===== PROTECTED POD =====
NAME                                 READY   STATUS    RESTARTS   AGE     IP           NODE                 NOMINATED NODE   READINESS GATES
protected-service-67fd8f9848-99ffc   1/1     Running   0          3m57s   10.244.1.6   autoscaling-worker   <none>           <none>

===== POD DISRUPTION BUDGET =====
NAME                    MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
protected-service-pdb   1               N/A               0                     3m57s

===== DRAIN EVIDENCE =====
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
There are pending pods in node "autoscaling-worker" when an error occurred: error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default": global timeout reached: 1m30s
error: unable to drain node "autoscaling-worker" due to error: error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default": global timeout reached: 1m30s, continuing command...
There are pending nodes to be drained:
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default": global timeout reached: 1m30s
Drain exit code: 1
Drain exit code: 

## Scale-Up Decision Evidence

The workload generated genuine Kubernetes scheduling pressure. The following
scheduler output records pods that could not be placed because their aggregate
CPU requests exceeded worker capacity:

```text
scheduling-pressure-6bbf4ffcb4-9g448   0/1     Pending   0          85s    <none>       <none>                <none>           <none>
scheduling-pressure-6bbf4ffcb4-f7jpl   0/1     Pending   0          85s    <none>       <none>                <none>           <none>
REASON=Unschedulable MESSAGE=0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient cpu. no new claims to deallocate, preemption: 0/3 nodes are available: 1 Preemption is not helpful for scheduling, 2 No preemption victims found for incoming pod.
REASON=Unschedulable MESSAGE=0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient cpu. no new claims to deallocate, preemption: 0/3 nodes are available: 1 Preemption is not helpful for scheduling, 2 No preemption victims found for incoming pod.
85s         Warning   FailedScheduling          pod/scheduling-pressure-6bbf4ffcb4-9g448    0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient cpu. no new claims to deallocate, preemption: 0/3 nodes are available: 1 Preemption is not helpful for scheduling, 2 No preemption victims found for incoming pod.
85s         Warning   FailedScheduling          pod/scheduling-pressure-6bbf4ffcb4-f7jpl    0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient cpu. no new claims to deallocate, preemption: 0/3 nodes are available: 1 Preemption is not helpful for scheduling, 2 No preemption victims found for incoming pod.
```

A physical node addition did not occur because the kind workers are not owned
by a resizable infrastructure node group.

## Scale-Down and PDB Evidence

The protected workload used a PodDisruptionBudget with `minAvailable: 1`.
The following drain output demonstrates the protection:

```text
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
There are pending pods in node "autoscaling-worker" when an error occurred: error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default": global timeout reached: 1m30s
error: unable to drain node "autoscaling-worker" due to error: error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default": global timeout reached: 1m30s, continuing command...
There are pending nodes to be drained:
error when evicting pods/"protected-service-67fd8f9848-99ffc" -n "default": global timeout reached: 1m30s
Drain exit code: 1
Drain exit code: 
```

## Protected Pod Observation

```text

Timestamp: 2026-07-16T16:12:16+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:12:19+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:12:21+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:12:23+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:12:25+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:12:27+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:12:29+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:12:31+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:12:34+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:12:36+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:12:38+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:12:40+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:12:42+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:12:44+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:12:46+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:12:48+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:12:51+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:12:53+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:12:55+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:12:57+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:12:59+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:01+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:03+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:05+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:08+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:10+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:12+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:14+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:16+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:18+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:20+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:23+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:25+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:27+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:29+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:31+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:33+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:35+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:37+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:40+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:42+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:44+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:46+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:48+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:50+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:52+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:54+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:56+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:13:59+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:14:01+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:14:03+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:14:05+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:14:07+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:14:09+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>

Timestamp: 2026-07-16T16:14:11+00:00
NAME                                 STATUS    NODE                 DELETION-TIMESTAMP
protected-service-67fd8f9848-99ffc   Running   autoscaling-worker   <none>
```

## Node-Group Boundary Evidence

```yaml
apiVersion: v1
data:
  expander: least-waste
  implementation-status: |
    Policy documented for a provider-managed node group.
    The current kind workers are Docker containers and are not members of a
    resizable AWS Auto Scaling Group or Cluster API MachineDeployment.
  maximum-nodes: "5"
  minimum-nodes: "2"
  scale-down-delay-after-add: 2m
  scale-down-unneeded-time: 2m
  scale-down-utilization-threshold: "0.5"
kind: ConfigMap
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","data":{"expander":"least-waste","implementation-status":"Policy documented for a provider-managed node group.\nThe current kind workers are Docker containers and are not members of a\nresizable AWS Auto Scaling Group or Cluster API MachineDeployment.\n","maximum-nodes":"5","minimum-nodes":"2","scale-down-delay-after-add":"2m","scale-down-unneeded-time":"2m","scale-down-utilization-threshold":"0.5"},"kind":"ConfigMap","metadata":{"annotations":{},"name":"autoscaler-node-group-policy","namespace":"kube-system"}}
  creationTimestamp: "2026-07-16T16:15:05Z"
  name: autoscaler-node-group-policy
  namespace: kube-system
  resourceVersion: "2251"
  uid: b11f733c-7050-46d9-b1c6-69bd06ab2bad
```

## Scaling Explanation

The cluster generated real scheduling pressure, but kind did not add or remove worker nodes because its workers are Docker containers rather than members of a provider-managed node group. Cluster Autoscaler requires an infrastructure adapter such as an AWS Auto Scaling Group or Cluster API MachineDeployment to execute node-count changes. The intended minimum of two and maximum of five nodes were documented but could not be enforced by kind itself. During the scale-down simulation, Kubernetes attempted to drain the worker hosting the protected service. The PodDisruptionBudget required one available replica, while the deployment had only one replica. Kubernetes therefore rejected the eviction, the drain did not complete, and the protected pod remained running. This demonstrates that the disruption policy correctly prevented a voluntary action that would have reduced service availability to zero.
