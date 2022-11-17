//import QTIKit
//import KognitaModels
//
//struct QTIBridge {
//    static func convertToTask(assessmentItems: [AssessmentItem]) -> [MultipleChoiceTask.Create.Data] {
//
//        for item in assessmentItems {
//            let choices = item.itemBody.choiceInteraction.choices.map {
//                MultipleChoiceTaskChoice.Create.Data(
//                    choice: $0.choice,
//                    isCorrect: item.response.correctResponse.values.contains($0.id)
//                )
//            }
//        }
//        return []
//    }
//}
