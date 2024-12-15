<%-- 
    Document   : result
    Created on : 24 Nov 2024, 8:03:34?pm
    Author     : Admin
--%>

<%-- 
    Document   : index
    Created on : 26 Nov 2024, 8:46:22?pm
    Author     : Admin
--%>

<%@page import="edu.stanford.nlp.util.CoreMap"%>
<%@ page import="edu.stanford.nlp.pipeline.*" %>
<%@ page import="edu.stanford.nlp.ling.*" %>
<%@ page import="edu.stanford.nlp.sentiment.*" %>

<%@ page import="java.util.*" %>
<%
    // Default text for sentiment analysis
    String inputText = request.getParameter("text");
    String sentimentResult = "";

    if (inputText != null && !inputText.trim().isEmpty()) {
        // Set up Stanford CoreNLP pipeline
        Properties props = new Properties();
        props.setProperty("annotators", "tokenize,ssplit,pos,lemma,parse,sentiment");
        StanfordCoreNLP pipeline = new StanfordCoreNLP(props);

        // Annotate the text
        Annotation document = new Annotation(inputText);
        pipeline.annotate(document);

        // Retrieve sentences and analyze sentiment
        List<CoreMap> sentences = document.get(CoreAnnotations.SentencesAnnotation.class);

        // Analyzing sentiment for each sentence
        StringBuilder sentimentAnalysisResult = new StringBuilder();
        for (CoreMap sentence : sentences) {
            String sentiment = sentence.get(SentimentCoreAnnotations.SentimentClass.class);
            sentimentAnalysisResult.append("Sentence: ").append(sentence.toString())
                                   .append("<br>Sentiment: ").append(sentiment).append("<br>");
        }

        sentimentResult = sentimentAnalysisResult.toString();
    } else {
        sentimentResult = "No text provided for analysis.";
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sentiment Analysis</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            border: 1px solid #ccc;
            border-radius: 10px;
        }
        .result {
            margin-top: 20px;
            padding: 10px;
            border: 1px solid #ddd;
            background-color: #f9f9f9;
        }
        .form-group {
            margin-bottom: 15px;
        }
        textarea {
            width: 100%;
            height: 150px;
            padding: 10px;
            font-size: 16px;
            border-radius: 5px;
            border: 1px solid #ccc;
        }
        button {
            padding: 10px 20px;
            font-size: 16px;
            cursor: pointer;
            background-color: #28a745;
            color: white;
            border: none;
            border-radius: 5px;
        }
    </style>
</head>
<body>

<div class="container">
    <h1>Sentiment Analysis</h1>
    
    <form method="get" action="index.jsp">
        <div class="form-group">
            <label for="text">Enter Text for Sentiment Analysis:</label>
            <textarea id="text" name="text"></textarea>
        </div>
        <button type="submit">Analyze Sentiment</button>
    </form>

    <div class="result">
        <h3>Analysis Result:</h3>
        <p><%= sentimentResult %></p>
    </div>
</div>

</body>
</html>
