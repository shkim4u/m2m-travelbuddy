import streamlit as st
import requests
import time
from PIL import Image
from ssm_utils import *

image = Image.open("./img/sagemaker.png")
st.image(image, width=80)
st.header("Text Generation")
st.caption("Using CodeLlama2-7B-Instruct model from SageMaker JumpStart")

conversation = """
SAST tool has found that the following code has command injection vulnerablity:
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

    endpoint_name = st.sidebar.text_input("SageMaker Endpoint Name:", sm_endpoint)
    url = st.sidebar.text_input("APIGW Url:", apigw_endpoint)

    context = st.text_area("Input Context:", conversation, height=400)

    queries = "Do you think this code really is vulnerable and if so, please tell me how to fix it."

    selection = st.selectbox("Select a query:", queries)

    if st.button("Generate Response", key=selection):
        if endpoint_name == "" or selection == "" or url == "":
            st.error("Please enter a valid endpoint name, API gateway url and prompt!")
        else:
            with st.spinner("Wait for it..."):
                try:
                    prompt = f"{context}\n{selection}"
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
