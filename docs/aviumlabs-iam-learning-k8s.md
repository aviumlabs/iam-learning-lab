Avium Labs IAM Learning Lab Docker Environment Guide (c) by Michael Konrad

Avium Labs IAM Learning Lab Docker Environment is licensed under a
Creative Commons Attribution 4.0 International License.

You should have received a copy of the license along with this
work. If not, see <http://creativecommons.org/licenses/by/4.0/>


Check for syntax errors: 
```
helm lint ./tck8s-app
```

Run a dry-run:
```
helm install --dry-run --debug kck8s-iam-release ./tck8s-app
```

Deploy to MicroK8s:
```
helm install kck8s-iam-release ./tck8s-app
```

