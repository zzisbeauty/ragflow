import os, pathlib
print("CWD :", os.getcwd())

from ragflow_sdk import RAGFlow


  
# 初始化客户端  
api_key = "ragflow-I5YjVjYTg2NWM5MTExZjA4ODJkYzYxN2"  # 替换为您的实际 API key  
base_url = "http://localhost:9380"  # 替换为您的 RAGFlow 服务地址  
  
rag = RAGFlow(api_key=api_key, base_url=base_url)  

# # 创建数据集  
# dataset = rag.create_dataset(name="my_test_dataset_hlm_demo")  
# print(f"Created dataset: {dataset.name} with ID: {dataset.id}") 


# 列出所有现有的知识库  
datasets = rag.list_datasets()
# 让用户选择知识库  
choice = int(input("请选择知识库编号: "))  
dataset = datasets[choice]  
print(f"已选择知识库: {dataset.name}")  


# 上传文档  
with open("./test/testcases/test_datas/矢量版-现行_SL310-2019《村镇供水工程技术规范》.pdf", "rb") as f:  
    blob = f.read()  


documents = [{  
    "display_name": "hlm_demo.txt",  
    "blob": blob  
}]

uploaded_docs = dataset.upload_documents(documents)  
print(f"Uploaded {len(uploaded_docs)} documents")  

# 解析文档  
doc_ids = [doc.id for doc in uploaded_docs]  
dataset.async_parse_documents(doc_ids)  
print("Document parsing initiated")  

# 检索文本块  
chunks = rag.retrieve(dataset_ids=[dataset.id])  
for chunk in chunks:  
    print(f"Chunk content: {chunk.content}")