package eu.whiskrkit.flutter_whiskrkit

import eu.whiskrkit.SurveyCompletion
import eu.whiskrkit.SurveyCompletion.Answer
import eu.whiskrkit.SurveyCompletion.QuestionType
import eu.whiskrkit.SurveyCompletion.Value
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/*
 * Unit tests of the plugin's pure Kotlin parts. Run them with
 * `./gradlew :flutter_whiskrkit:testDebugUnitTest` in `example/android/`
 * after building the example app once.
 */
internal class FlutterWhiskrkitPluginTest {
    @Test
    fun completionMapMatchesTheShapeTheDartSideReads() {
        val completion = SurveyCompletion(
            "s1",
            listOf(
                Answer("s1-q1", QuestionType.SCALE_RATING, Value.Score(9)),
                Answer("s1-q2", QuestionType.THUMBS_RATING, Value.Thumbs(isUp = true)),
                Answer("s1-q3", QuestionType.TEXTUAL_SURVEY, Value.Text("Great")),
                Answer("s1-q4", QuestionType.MULTIPLE_CHOICE, Value.Choices(listOf("a", "c"))),
            ),
        )

        assertEquals(
            mapOf(
                "surveyId" to "s1",
                "answers" to listOf(
                    mapOf("questionId" to "s1-q1", "questionType" to "scaleRating", "valueType" to "score", "value" to 9),
                    mapOf("questionId" to "s1-q2", "questionType" to "thumbsRating", "valueType" to "thumbs", "value" to true),
                    mapOf("questionId" to "s1-q3", "questionType" to "textualSurvey", "valueType" to "text", "value" to "Great"),
                    mapOf("questionId" to "s1-q4", "questionType" to "multipleChoice", "valueType" to "choices", "value" to listOf("a", "c")),
                ),
            ),
            completion.toChannelMap(),
        )
    }

    @Test
    fun everyQuestionTypeHasTheSameNameAsOnIos() {
        assertEquals(
            listOf("scaleRating", "symbolRating", "thumbsRating", "textualSurvey", "multipleChoice"),
            QuestionType.entries.map { it.channelName },
        )
    }

    @Test
    fun attributeValuesAreStringsNumbersAndBools() {
        assertTrue(isAttributeValue("pro"))
        assertTrue(isAttributeValue(true))
        assertTrue(isAttributeValue(3))
        assertTrue(isAttributeValue(3L))
        assertTrue(isAttributeValue(0.5))
        assertFalse(isAttributeValue(Double.NaN))
        assertFalse(isAttributeValue(Double.POSITIVE_INFINITY))
        assertFalse(isAttributeValue(listOf(1)))
        assertFalse(isAttributeValue(mapOf("a" to 1)))
    }
}
