<%@page import="org.ejml.simple.SimpleMatrix"%>
<%@page import="edu.stanford.nlp.util.CoreMap"%>
<%@page import="edu.stanford.nlp.pipeline.*"%>
<%@page import="edu.stanford.nlp.ling.*"%>
<%@page import="edu.stanford.nlp.sentiment.*"%>
<%@page import="edu.stanford.nlp.trees.Tree"%>
<%@page import="edu.stanford.nlp.neural.rnn.RNNCoreAnnotations"%>
<%@page import="java.sql.*"%>
<%@page import="java.util.*"%>

<%
    // Database connection parameters
    String dbURL = "jdbc:mariadb://localhost:3306/sentiment_analysis";
    String dbUser = "root"; // Replace with your database username
    String dbPassword = "root"; // Replace with your database password

    String inputText = request.getParameter("text");
    String sentimentResult = "";

    if (inputText != null && !inputText.trim().isEmpty()) {
        // Initialize Stanford CoreNLP pipeline
        Properties props = new Properties();
        props.setProperty("annotators", "tokenize,ssplit,pos,lemma,parse,sentiment");
        StanfordCoreNLP pipeline = new StanfordCoreNLP(props);

        // Annotate the text
        Annotation document = new Annotation(inputText);
        pipeline.annotate(document);

        // Retrieve sentences from the input text
        List<CoreMap> sentences = document.get(CoreAnnotations.SentencesAnnotation.class);

        // Database connection and insertion
        Connection conn = null;
        PreparedStatement stmt = null;

        try {
             Class.forName("org.mariadb.jdbc.Driver");
            conn = DriverManager.getConnection(dbURL, dbUser, dbPassword);

            String insertQuery = "INSERT INTO sentiment_analysis_results "
                               + "(input_text, sentence, sentiment, very_negative_score, negative_score, "
                               + "neutral_score, positive_score, very_positive_score) "
                               + "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
            stmt = conn.prepareStatement(insertQuery);

            // Analyze each sentence and insert results into the database
            StringBuilder sentimentAnalysisResult = new StringBuilder();
            for (CoreMap sentence : sentences) {
                // Get sentiment class
                String sentiment = sentence.get(SentimentCoreAnnotations.SentimentClass.class);

                // Get sentiment scores using SentimentAnnotatedTree
                Tree tree = sentence.get(SentimentCoreAnnotations.SentimentAnnotatedTree.class);
                SimpleMatrix scores = RNNCoreAnnotations.getPredictions(tree);
                double veryNegative = scores.get(0);
                double negative = scores.get(1);
                double neutral = scores.get(2);
                double positive = scores.get(3);
                double veryPositive = scores.get(4);

                // Append results for display
                sentimentAnalysisResult.append("Sentence: ").append(sentence.toString())
                                       .append("<br>Sentiment: ").append(sentiment)
                                       .append("<br>Scores: ")
                                       .append("Very Negative: ").append(String.format("%.2f", veryNegative)).append(", ")
                                       .append("Negative: ").append(String.format("%.2f", negative)).append(", ")
                                       .append("Neutral: ").append(String.format("%.2f", neutral)).append(", ")
                                       .append("Positive: ").append(String.format("%.2f", positive)).append(", ")
                                       .append("Very Positive: ").append(String.format("%.2f", veryPositive))
                                       .append("<br><br>");

                // Insert into database
                stmt.setString(1, inputText);
                stmt.setString(2, sentence.toString());
                stmt.setString(3, sentiment);
                stmt.setDouble(4, veryNegative);
                stmt.setDouble(5, negative);
                stmt.setDouble(6, neutral);
                stmt.setDouble(7, positive);
                stmt.setDouble(8, veryPositive);
                stmt.executeUpdate();
            }

            sentimentResult = sentimentAnalysisResult.toString();
        } catch (SQLException e) {
            e.printStackTrace();
            sentimentResult = "Error storing results in the database: " + e.getMessage();
        } finally {
            if (stmt != null) try { stmt.close(); } catch (SQLException ignored) {}
            if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
        }
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
