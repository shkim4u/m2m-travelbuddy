import streamlit as st
import requests
import time
from PIL import Image
from ssm_utils import *

image = Image.open("./img/sagemaker.png")
st.image(image, width=80)
st.header("Text Generation")
st.caption("Using CodeLlama2 model from SageMaker JumpStart")

conversation = """
SAST tool has found that the following code has command injection vulnerability:
    public String sendMail(String[] cmd)
    {
        Runtime rt = Runtime.getRuntime();
        //call "legacy" mail program
        Process proc = null;
        StringBuilder message = new StringBuilder();
        try
        {
            if(cmd!=null){
                System.out.println(cmd[0]);
                System.out.println(cmd[1]);
                System.out.println(cmd[2]);
            }
            else{
                System.out.println("cmd is empty!");
            }

            proc = rt.exec(cmd);

            InputStream is = proc.getInputStream();
            int read;
            while( (read = is.read()) > 0)
            {
                message.append((char)read);
            }
        }
        catch(Exception e)
        {
            e.printStackTrace();
            System.out.println(e.getMessage());
            System.out.println(e.getLocalizedMessage());
        }
        finally
        {
            if (proc != null)
                proc.destroy();
        }

        //update local mail too
        updateMail();
        return message.toString();
    }

Do you think this code really is vulnerable and if so, please tell me how to fix it.
"""

with st.spinner("Retrieving configurations..."):
    all_configs_loaded = False

    while not all_configs_loaded:
        try:
            apigw_endpoint = get_parameter(key_text_generation_apigateway_endpoint)
            sm_endpoint = get_parameter(key_text_generation_sagemaker_endpoint)
            all_configs_loaded = True
        except:
            time.sleep(5)

    endpoint_name = st.sidebar.text_input("세이지메이커 엔드포인트 이름:", sm_endpoint)
    url = st.sidebar.text_input("APIGW Url:", apigw_endpoint)
    # Rewrite the caption with model endpoint.
    st.caption("Using CodeLlama2 model from SageMaker JumpStart endpoint: ", sm_endpoint)

    context = st.text_area("입력 컨텍스트:", conversation, height=600)

    if st.button("모델 호출"):
        if endpoint_name == "" or url == "":
            st.error("모델 엔드포인 혹은 API 게이트웨이 URL이 유효하지 않습니다!")
        else:
            with st.spinner("Wait for it..."):
                try:
                    # prompt = f"{context}\n{selection}"
                    prompt = f"{context}"
                    r = requests.post(url, json={"prompt": prompt, "endpoint_name": endpoint_name}, timeout=180)
                    data = r.json()
                    generated_text = data["generated_text"]
                    st.write(generated_text)

                except requests.exceptions.ConnectionError as errc:
                    st.error("Error Connecting:", errc)

                except requests.exceptions.HTTPError as errh:
                    st.error("Http Error:", errh)

                except requests.exceptions.Timeout as errt:
                    st.error("Timeout Error:", errt)

                except requests.exceptions.RequestException as err:
                    st.error("OOps: Something Else", err)

            st.success("Done!")
