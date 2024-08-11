import os
import chromadb
from dataclasses import dataclass
from langchain_chroma import Chroma
from chromadb import Documents, EmbeddingFunction, Embeddings
import google.generativeai as genai


class GeminiEmbeddingFunction(EmbeddingFunction):
  def __call__(self, input: Documents) -> Embeddings:
    model = 'models/text-embedding-004'
    title = "Airline reviews"
    return genai.embed_content(model=model,
                                content=input,
                                task_type="RETRIEVAL_DOCUMENT",
                                title=title)["embedding"]


@dataclass
class CreateVectorStore:

    reload : bool
    documents_dir : str = "../Documents/"
    vector_store_dir : str = "../Vectorstore/"
    vector_store_name : str = "airline_db"
    GOOGLE_API_KEY = """INSERT GEMINI API KEY"""
    
    def __post_init__(self):
        genai.configure(api_key=self.GOOGLE_API_KEY)
        #self.vector_store = Chroma(embedding_function=embed_text)
        self.client = chromadb.PersistentClient()
        self.collection = self.client.get_or_create_collection(name="Reviews",
                                                               embedding_function=GeminiEmbeddingFunction())
        if self.reload:
            self._read_documents()
            self._create_database()

    def query(self, query, top_k=2):
        results = self.collection.query(
            query_texts=[query],
            n_results=top_k
        )
        return " ".join(results['documents'][0])

    def _read_documents(self):
        self.documents = []
        for filename in os.listdir(self.documents_dir):
            if filename.endswith('.txt'):
                file_path = os.path.join(self.documents_dir, filename)
                with open(file_path, 'r', encoding='utf-8') as file:
                    content = file.read()
                    self.documents.append(content)
        return True
    
    def _create_database(self):
        self.collection.add(
            documents = self.documents,
            #metadatas = [{"source": "student info"},{"source": "club info"},{'source':'university info'}],
            ids = [str(x) for x in range(len(self.documents))]
        )