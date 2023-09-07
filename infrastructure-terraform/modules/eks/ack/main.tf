resource "kubernetes_namespace" "ack" {
  metadata {
    name = local.namespace
    labels = {
      purpose = "aws-controller-kubernetes"
    }
  }
}

## References
## - Required IRSA: https://aws-controllers-k8s.github.io/community/docs/user-docs/irsa/
/**
# Download the recommended managed and inline policies and apply them to the
# newly created IRSA role
BASE_URL=https://raw.githubusercontent.com/aws-controllers-k8s/${SERVICE}-controller/main
echo $BASE_URL

POLICY_ARN_URL=${BASE_URL}/config/iam/recommended-policy-arn
echo $POLICY_ARN_URL

POLICY_ARN_STRINGS="$(wget -qO- ${POLICY_ARN_URL})"
echo $POLICY_ARN_STRINGS
# (참고) 람다는 위 환경변수에 값이 없음, 즉, Managed Policy가 정의되어 있지 않음.

INLINE_POLICY_URL=${BASE_URL}/config/iam/recommended-inline-policy
echo $INLINE_POLICY_URL

INLINE_POLICY="$(wget -qO- ${INLINE_POLICY_URL})"
echo $INLINE_POLICY

while IFS= read -r POLICY_ARN; do
echo -n "Attaching $POLICY_ARN ... "
aws iam attach-role-policy \
--role-name "${ACK_CONTROLLER_IAM_ROLE}" \
--policy-arn "${POLICY_ARN}"
echo "ok."
done <<< "$POLICY_ARN_STRINGS"

if [ ! -z "$INLINE_POLICY" ]; then
echo -n "Putting inline policy ... "
aws iam put-role-policy \
--role-name "${ACK_CONTROLLER_IAM_ROLE}" \
--policy-name "ack-recommended-policy" \
--policy-document "$INLINE_POLICY"
echo "ok."
fi
*/
module "ack_lambda" {
  source = "./lambda"
  namespace = local.namespace
  service_account_role_arn = "arn:aws:iam::861063945558:role/aws-controller-kubernetes-lambda"
}
