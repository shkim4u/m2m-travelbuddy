import streamlit as st
import os

from PIL import Image
image = Image.open("./img/sagemaker.png")
st.image(image, width=80)

version = os.environ.get("WEB_VERSION", "0.1")

st.header(f"AppSec을 위한 Generative AI 데모 (버전: {version})")
st.markdown("Amazon SageMaker JumpStart를 통해 배포된 Generative AI (CodeLlama2-7B-Instruct)를 활용하는 데모입니다.")
st.markdown("_사이드 바에서 옵션을 선택하세요 (현재는 텍스트 생성 옵선만 선택 가능)_")
