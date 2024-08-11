import re
from datetime import datetime
import google.generativeai as genai
from create_vectorstore_public import CreateVectorStore
from query_airline import ExpediaFlightResultsGetter
from google.generativeai.types import HarmCategory, HarmBlockThreshold, GenerationConfig


class QueryGeminiModel:

    GOOGLE_API_KEY = """INSERT GEMINI API KEY"""

    def __init__(self, model_name='models/gemini-1.5-flash') -> None:
        genai.configure(api_key=self.GOOGLE_API_KEY)
        safety_settings = [
                    {
                        HarmCategory.HARM_CATEGORY_HARASSMENT : HarmBlockThreshold.BLOCK_NONE,
                        HarmCategory.HARM_CATEGORY_HARASSMENT : HarmBlockThreshold.BLOCK_NONE,
                        HarmCategory.HARM_CATEGORY_HARASSMENT : HarmBlockThreshold.BLOCK_NONE,
                        HarmCategory.HARM_CATEGORY_HARASSMENT : HarmBlockThreshold.BLOCK_NONE,
                        "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
                        "threshold": "BLOCK_NONE",
                    },
        ]
        config = GenerationConfig(
                    max_output_tokens=2048, temperature=1., top_p=1, top_k=32
                )
        self.model = genai.GenerativeModel(model_name, 
                                           safety_settings=safety_settings,
                                           generation_config=config)
        
        self.current_date = datetime.today().strftime('%m-%d-%Y')
        
        
        self.chat = self.model.start_chat(history=[
            {
            'role': 'user',
            'parts': [f"""You are a travel advisor that can choose to parse website info to provide the best
                      deals on flights for the user.
                      If the user's query is flight or travel related, you may choose to first search for results on
                      the web, by only returning: Search[user's flight query], which searches the flight requested on expedia and returns the result.
                      Please format your query as a comma-separated string, in the following format: from airport, to airport,
                      arrival date (mm/dd/yyyy), leaving date (mm/dd/yyyy), cabin class (economy/premium_economy/business/first),
                      number of travelers.
                      Today's date is {self.current_date}. If leaving date is not given, then assume the user is staying for one week. For all
                      other categories, USE YOUR BEST JUDGEMENT. Please do not respond with inaccurate results, and only return results that 
                      have been given to you as result of a search.
                      The result of your search is returned in the format Result[search results] + user's query.
                      If the user's question is not flight related, then 
                      behave like a normal chatbot."""]
            },
            {
                'role': 'model',
                'parts': ['Sure.'],
            }
            ])
        
        self.search_result_prompt = """Here is the result of your search. Please mention at the beginning of your message important search criteria: \
        arrival date {}, leaving date {}, cabin class {}. Please summarise ALL options in FULL detail to the user in a presentable format.\
        If there are none or erroneous results, please apologize and tell the user to try another destination. Additionally, you have been provided with\
         some potentially relevant user review information about some airlines. Only use this information if the review strictly describes one of the\
         airlines from the search results. Please highlight positives and negatives before giving your opinion on the best airline, depending on the\
         ticket price, review information or other."""

        self.rag_db = CreateVectorStore(True,
                                        "Documents",
                                        "Vectorstore")

    def query(self, prompt):
        response = self.chat.send_message(prompt).text

        if "Search[" in response:
            pattern = r"Search\[(.*?)\]"
            match = re.search(pattern, response).group(1)
            print("Searching: ", match)
            search_results = ExpediaFlightResultsGetter().get(match)
            print(self.search_result_prompt.format(*match.split(",")[-4:])
                                              + " Result[" + search_results + "]. " 
                                              + "User review information: " + self.rag_db.query(search_results)
                                              + "User query: " + prompt)
            response = self.chat.send_message(self.search_result_prompt.format(*match.split(",")[-4:])
                                              + " Result[" + search_results + "]. " 
                                              + "User review information: " + self.rag_db.query(search_results)
                                              + "User query: " + prompt).text

        return response