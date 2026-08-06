import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/services/question_split_service.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_session.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

void main() {
  group('QuestionSplitService.split', () {
    const splitter = QuestionSplitService();

    test('splits numbered questions into multiple candidates', () async {
      final result = await splitter.split('1. 已知 x+1=3，求 x\n2. 已知 y-2=0，求 y');

      expect(result.strategy, QuestionSplitStrategy.numbered);
      expect(
          result.candidates.map((candidate) => candidate.text).toList(),
          <String>[
            '1. 已知 x+1=3，求 x',
            '2. 已知 y-2=0，求 y',
          ]);
    });

    test('splits blank-line separated questions into multiple candidates',
        () async {
      final result = await splitter.split('已知 x+1=3，求 x\n\n已知 y-2=0，求 y');

      expect(result.strategy, QuestionSplitStrategy.paragraph);
      expect(
          result.candidates.map((candidate) => candidate.text).toList(),
          <String>[
            '已知 x+1=3，求 x',
            '已知 y-2=0，求 y',
          ]);
    });

    test('keeps English cloze passage as one composite question', () async {
      const text = '''1. Saving for a Rainy Day
In China, saving money has always been considered a traditional virtue. Chinese people _____ 1 _____ the habit of putting money aside.
Some young people save income, _____ 4 _____ spend most of it on travel.
1. A. keep B. kept C. have kept
2. A. saved B. was saved C. has saved
3. A. to interest B. interesting C. interested
4. A. others B. the other C. another
5. A. find B. finding C. to find''';

      final result = await splitter.split(text);

      expect(result.strategy, QuestionSplitStrategy.fallback);
      expect(result.candidates, hasLength(1));
      expect(result.candidates.single.text, text);
    });

    test('keeps Chinese classical worksheet as one composite question',
        () async {
      const text = '''《桃花源记》翻译卷
一、文常积累
本文作者______，名______，字______。
二、字词释义
晋太元中，武陵人捕鱼为业。缘（______）溪行，忘路之远近。忽逢桃花林，夹岸数百步，中无杂树，芳草鲜美（______），落英（______）缤纷（______）。''';

      final result = await splitter.split(text);

      expect(result.strategy, QuestionSplitStrategy.fallback);
      expect(result.candidates, hasLength(1));
      expect(result.candidates.single.text, text);
    });

    test('keeps history long fill-in worksheet as one composite question',
        () async {
      const text = '''中国古代史阶段复习填空
一、先秦时期
1. 西周实行______制，形成天子、诸侯、卿大夫、士的等级秩序。
2. 春秋战国时期，______变法推动秦国国力增强，为统一奠定基础。
二、秦汉时期
3. 秦始皇统一后建立______制度，地方推行______制。
4. 汉武帝接受董仲舒建议，实行“______”，加强思想控制。
三、隋唐至明清
5. 隋唐时期完善______制，扩大官吏选拔范围。
6. 明清时期君主专制强化，军机处设立于______时期。
请结合材料，概括这些制度变化对统一多民族国家发展的影响。''';

      final result = await splitter.split(text, subject: Subject.history);

      expect(result.strategy, QuestionSplitStrategy.fallback);
      expect(result.candidates, hasLength(1));
      expect(result.candidates.single.text, text);
    });

    test('keeps politics long fill-in worksheet as one composite question',
        () async {
      const text = '''道德与法治综合填空题
一、公民权利
1. 公民最基本、最重要的权利是______。
2. 依法行使权利时，不得损害国家的、社会的、集体的利益和其他公民的______。
二、国家制度
3. 我国的根本政治制度是______。
4. 全国人民代表大会是最高______机关。
三、法治建设
5. 全面依法治国的总目标是建设中国特色社会主义______体系。
6. 厉行法治要求推进科学立法、严格执法、公正司法、______守法。
请根据材料说明公民参与法治建设的意义。''';

      final result = await splitter.split(text, subject: Subject.politics);

      expect(result.strategy, QuestionSplitStrategy.fallback);
      expect(result.candidates, hasLength(1));
      expect(result.candidates.single.text, text);
    });

    test('still splits numbered math questions with blanks', () async {
      const text = '''1. 已知 x+______=3，求 x。
2. 已知 y-______=0，求 y。''';

      final result = await splitter.split(text, subject: Subject.math);

      expect(result.strategy, QuestionSplitStrategy.numbered);
      expect(result.candidates, hasLength(2));
    });

    test('keeps chemistry synthesis stem with subquestions as one question',
        () async {
      const text = '''9. 某治疗胃炎药物的中间体 N，可通过如下合成路线制得。
A(C6H6) -> B -> D -> E -> F，条件：重排指有机分子中的一个基团迁移到另一个原子上。
（1）A→B 的反应类型是______。
（2）按官能团分类，D 的类别是______。
（3）E 含有醚键，E 的结构简式是______。
（4）写出符合条件的 F 的同分异构体______。
（5）F 与 NH2OH 反应生成 G 的过程如下。
（6）J 含有酰胺键，试剂 a 是______。
（7）K 与 NaOH 反应得到 L 的化学方程式是______。''';

      final result = await splitter.split(text, subject: Subject.chemistry);

      expect(result.strategy, QuestionSplitStrategy.fallback);
      expect(result.candidates, hasLength(1));
      expect(result.candidates.single.text, text);
    });

    test('keeps math geometry stem with subquestions as one question',
        () async {
      const text = '''如图，在正方形 ABCD 中，E 是 BC 的中点，F 在 DC 上，连接 AE、FH。
（1）证明 FH 垂直平分 AE。
（2）若正方形边长为 2，求 DF 的长。''';

      final result = await splitter.split(text, subject: Subject.math);

      expect(result.strategy, QuestionSplitStrategy.fallback);
      expect(result.candidates, hasLength(1));
    });

    test('keeps physics circuit stem with subquestions as one question',
        () async {
      const text = '''如图所示电路中，电源电压保持不变，R1 与滑动变阻器 R2 串联。
（1）闭合开关后，求电流表示数。
（2）滑片向右移动时，判断电压表示数如何变化。''';

      final result = await splitter.split(text, subject: Subject.physics);

      expect(result.strategy, QuestionSplitStrategy.fallback);
      expect(result.candidates, hasLength(1));
    });

    test('keeps physics choice question with table and options as one question',
        () async {
      const text =
          r'''LED灯发光的颜色与其两端电压的对应关系如表1所示，LED灯发光时通过它的电流始终为 \(0.02\,\mathrm{A}\)。把这样的LED灯接入图3所示电路，闭合开关，当滑动变阻器的滑片在图示位置时，LED灯发出黄色的光。图3为由LED灯、滑动变阻器 \(R\)（滑片 \(P\) 在靠右位置）、电源和开关 \(S\) 组成的串联电路。下列方案中可使LED灯发红色的光的是（ ）

表1：
| LED灯两端的电压/\(\mathrm{V}\) | LED灯发光的颜色 |
|---|---|
| \(1.8\) | 红 |
| \(2.4\) | 黄 |
| \(3.2\) | 蓝 |

A. 向右移动滑片 \(P\)，电源电压一定变大
B. 向右移动滑片 \(P\)，电源电压可能变小
C. 向左移动滑片 \(P\)，电源电压可能不变
D. 向左移动滑片 \(P\)，电源电压一定变大''';

      final result = await splitter.split(text, subject: Subject.physics);

      expect(result.strategy, QuestionSplitStrategy.fallback);
      expect(result.candidates, hasLength(1));
      expect(result.candidates.single.text, contains('表1'));
      expect(result.candidates.single.text, contains('A. 向右移动滑片'));
    });

    test(
        'keeps physics choice question with decimal table rows as one question',
        () async {
      const text = r'''LED灯发光的颜色与其两端电压的对应关系如表1所示。下列方案中可使LED灯发红色的光的是（ ）

\[
\begin{array}{c|c}
\text{LED灯两端的电压/伏} & \text{LED灯发光的颜色} \\
1.8 & \text{红} \\
2.4 & \text{黄} \\
3.2 & \text{蓝}
\end{array}
\]

A. 向右移动滑片 \(P\)，电源电压一定变大
B. 向右移动滑片 \(P\)，电源电压可能变小
C. 向左移动滑片 \(P\)，电源电压可能不变
D. 向左移动滑片 \(P\)，电源电压一定变大''';

      final result = await splitter.split(text, subject: Subject.physics);

      expect(result.strategy, QuestionSplitStrategy.fallback);
      expect(result.candidates, hasLength(1));
      expect(result.candidates.single.text, contains('1.8'));
      expect(result.candidates.single.text, contains('A. 向右移动滑片'));
    });

    test('keeps a single physics data question with a supporting table',
        () async {
      const text = r'''某同学利用图示电路测量小灯泡的电功率，实验中保持电源电压不变。

表1：
| 电压/\(\mathrm{V}\) | 电流/\(\mathrm{A}\) |
|---|---|
| \(2.0\) | \(0.20\) |
| \(2.5\) | \(0.24\) |
| \(3.0\) | \(0.28\) |

根据表1中的数据，求小灯泡在电压为 \(2.5\,\mathrm{V}\) 时的电功率。''';

      final result = await splitter.split(text, subject: Subject.physics);

      expect(result.strategy, QuestionSplitStrategy.fallback);
      expect(result.candidates, hasLength(1));
      expect(result.candidates.single.text, contains('表1'));
      expect(result.candidates.single.text, contains('电功率'));
    });

    test('still splits numbered physics choice questions', () async {
      const text = r'''1. 下列关于串联电路的说法正确的是（ ）
A. 电流处处相等
B. 电压处处相等
C. 电阻一定相等
D. 功率一定相等

2. 下列关于并联电路的说法正确的是（ ）
A. 各支路电压相等
B. 各支路电流相等
C. 总电阻大于任一支路电阻
D. 开关只能控制全部支路''';

      final result = await splitter.split(text, subject: Subject.physics);

      expect(result.strategy, QuestionSplitStrategy.numbered);
      expect(result.candidates, hasLength(2));
      expect(result.candidates.first.text, startsWith('1.'));
      expect(result.candidates.last.text, startsWith('2.'));
    });

    test('still splits extracted independent math question list', () async {
      const text = r'''1. 已知 \(x^{2}+1=5\)，求 \(x\) 的值。

2. 若 \(\frac{a}{b}=2\)，且 \(a+b=9\)，求 \(a\) 和 \(b\) 的值。

3. 函数 \(f(x)=x^{2}-2x+1\) 在 \(x=3\) 时的值是多少？

4. 解方程组：\[\begin{cases} x+y=5 \\ x-y=1 \end{cases}\]

5. 圆锥体积公式为 \(V=\frac{1}{3}\pi r^{2}h\)。当 \(r=3\)，\(h=4\) 时，求 \(V\)。

6. 在 \(\triangle ABC\) 中，若 \(AB=AC\)，且 \(\angle A=40^\circ\)，求 \(\angle B\)。''';

      final result = await splitter.split(text, subject: Subject.math);

      expect(result.strategy, QuestionSplitStrategy.numbered);
      expect(result.candidates, hasLength(6));
      expect(result.candidates.first.text, startsWith('1.'));
      expect(result.candidates.last.text, startsWith('6.'));
    });

    test('still splits independent numbered chemistry questions', () async {
      const text = '''1. 写出钠与水反应的化学方程式。
2. 判断下列离子能否大量共存。
3. 计算一定量碳酸钙完全分解生成二氧化碳的质量。''';

      final result = await splitter.split(text, subject: Subject.chemistry);

      expect(result.strategy, QuestionSplitStrategy.numbered);
      expect(result.candidates, hasLength(3));
    });

    test('keeps single question as one candidate when no split markers',
        () async {
      final result = await splitter.split('已知 x^2+1=5，求 x 的值');

      expect(result.strategy, QuestionSplitStrategy.fallback);
      expect(result.candidates.map((candidate) => candidate.text).toList(),
          <String>['已知 x^2+1=5，求 x 的值']);
    });
  });

  test('buildQuestionSplitSession reuses existing split result', () async {
    final source = QuestionRecord.draft(
      id: 'q-2',
      imagePath: '',
      subject: Subject.math,
      recognizedText: '整题文本',
    ).copyWith(
      splitResult: const QuestionSplitResult(
        sourceText: '整题文本',
        strategy: QuestionSplitStrategy.numbered,
        candidates: <QuestionSplitCandidate>[
          QuestionSplitCandidate(
            id: 'candidate-0',
            order: 1,
            text: '第一题',
            strategy: QuestionSplitStrategy.numbered,
          ),
          QuestionSplitCandidate(
            id: 'candidate-1',
            order: 2,
            text: '第二题',
            strategy: QuestionSplitStrategy.numbered,
          ),
        ],
      ),
      candidateAnalyses: const <CandidateAnalysisSnapshot>[
        CandidateAnalysisSnapshot(
          candidateId: 'candidate-0',
          order: 1,
          questionText: '第一题',
          analysisResult: AnalysisResult(
            finalAnswer: 'A',
            steps: <String>[],
            aiTags: <String>[],
            knowledgePoints: <String>[],
            mistakeReason: '',
            studyAdvice: '',
          ),
        ),
        CandidateAnalysisSnapshot(
          candidateId: 'candidate-1',
          order: 2,
          questionText: '第二题',
          analysisResult: AnalysisResult(
            finalAnswer: 'B',
            steps: <String>[],
            aiTags: <String>[],
            knowledgePoints: <String>[],
            mistakeReason: '',
            studyAdvice: '',
          ),
        ),
      ],
    );

    final session = await buildQuestionSplitSession(source);

    expect(session.strategy, QuestionSplitStrategy.numbered);
    expect(session.drafts.map((draft) => draft.text).toList(),
        <String>['第一题', '第二题']);
  });

  test('buildQuestionSplitSession filters failed candidates from saving',
      () async {
    final source = QuestionRecord.draft(
      id: 'q-partial',
      imagePath: '',
      subject: Subject.math,
      recognizedText: '1. 第一题\n2. 第二题',
    ).copyWith(
      splitResult: const QuestionSplitResult(
        sourceText: '1. 第一题\n2. 第二题',
        strategy: QuestionSplitStrategy.numbered,
        candidates: <QuestionSplitCandidate>[
          QuestionSplitCandidate(
            id: 'candidate-1',
            order: 1,
            text: '第一题',
            strategy: QuestionSplitStrategy.numbered,
          ),
          QuestionSplitCandidate(
            id: 'candidate-2',
            order: 2,
            text: '第二题',
            strategy: QuestionSplitStrategy.numbered,
          ),
        ],
      ),
      candidateAnalyses: const <CandidateAnalysisSnapshot>[
        CandidateAnalysisSnapshot(
          candidateId: 'candidate-1',
          order: 1,
          questionText: '第一题',
          analysisResult: AnalysisResult(
            finalAnswer: 'A',
            steps: <String>['步骤'],
            aiTags: <String>[],
            knowledgePoints: <String>[],
            mistakeReason: '',
            studyAdvice: '',
          ),
        ),
        CandidateAnalysisSnapshot(
          candidateId: 'candidate-2',
          order: 2,
          questionText: '第二题',
          status: CandidateAnalysisStatus.failed,
          errorMessage: 'HTTP 503',
        ),
      ],
    );

    final session = await buildQuestionSplitSession(source);

    expect(session.failedCandidateCount, 1);
    expect(session.drafts, hasLength(1));
    expect(session.drafts.single.originalOrder, 1);
    expect(session.drafts.single.canSave, isTrue);
  });

  test('buildQuestionSplitSession blocks saving while a candidate retry runs',
      () async {
    final source = QuestionRecord.draft(
      id: 'q-retrying',
      imagePath: '',
      subject: Subject.math,
      recognizedText: '1. 第一题\n2. 第二题',
    ).copyWith(
      splitResult: const QuestionSplitResult(
        sourceText: '1. 第一题\n2. 第二题',
        strategy: QuestionSplitStrategy.numbered,
        candidates: <QuestionSplitCandidate>[
          QuestionSplitCandidate(
            id: 'candidate-1',
            order: 1,
            text: '第一题',
            strategy: QuestionSplitStrategy.numbered,
          ),
          QuestionSplitCandidate(
            id: 'candidate-2',
            order: 2,
            text: '第二题',
            strategy: QuestionSplitStrategy.numbered,
          ),
        ],
      ),
      candidateAnalyses: const <CandidateAnalysisSnapshot>[
        CandidateAnalysisSnapshot(
          candidateId: 'candidate-1',
          order: 1,
          questionText: '第一题',
          analysisResult: AnalysisResult(
            finalAnswer: 'A',
            steps: <String>[],
            aiTags: <String>[],
            knowledgePoints: <String>[],
            mistakeReason: '',
            studyAdvice: '',
          ),
        ),
        CandidateAnalysisSnapshot(
          candidateId: 'candidate-2',
          order: 2,
          questionText: '第二题',
          status: CandidateAnalysisStatus.running,
        ),
      ],
    );

    final session = await buildQuestionSplitSession(source);

    expect(session.drafts, hasLength(1));
    expect(session.failedCandidateCount, 0);
    expect(session.retryingCandidateCount, 1);
  });

  test(
      'buildSplitQuestionRecord stamps lineage metadata and candidate analysis',
      () {
    final now = DateTime(2026);
    final source = QuestionRecord.draft(
      id: 'root-1',
      imagePath: '/tmp/root.jpg',
      subject: Subject.math,
      recognizedText: '整题文本',
    ).copyWith(
      rootQuestionId: 'existing-root',
      splitResult: const QuestionSplitResult(
        sourceText: '整题文本',
        strategy: QuestionSplitStrategy.numbered,
        candidates: <QuestionSplitCandidate>[],
      ),
      candidateAnalyses: <CandidateAnalysisSnapshot>[
        CandidateAnalysisSnapshot(
          candidateId: 'candidate-2',
          order: 2,
          questionText: '第二题',
          analysisResult: const AnalysisResult(
            finalAnswer: 'B',
            steps: <String>['step'],
            aiTags: <String>['tag'],
            knowledgePoints: <String>['kp'],
            mistakeReason: 'reason',
            studyAdvice: 'advice',
            subject: Subject.physics,
          ),
          savedExercises: <GeneratedExercise>[
            GeneratedExercise(
              id: 'exercise-1',
              questionId: 'old-question',
              generationMode: ExerciseGenerationMode.practice,
              difficulty: '简单',
              question: '练习',
              answer: 'A',
              explanation: '解析',
              createdAt: now,
            ),
          ],
          subject: Subject.physics,
          aiTags: const <String>['tag'],
          aiKnowledgePoints: const <String>['kp'],
        ),
      ],
    );

    final child = buildSplitQuestionRecord(
      source: source,
      draft: const QuestionSplitDraft(
        id: 'candidate-2',
        text: '第二题',
        selected: true,
        originalOrder: 2,
      ),
      sortOrder: 2,
    );

    expect(child.id, 'root-1-2');
    expect(child.parentQuestionId, 'root-1');
    expect(child.rootQuestionId, 'existing-root');
    expect(child.splitOrder, 2);
    expect(child.subject, Subject.physics);
    expect(child.analysisResult?.finalAnswer, 'B');
    expect(child.savedExercises.single.questionId, 'root-1-2');
    expect(child.aiTags, <String>['tag']);
    expect(child.aiKnowledgePoints, <String>['kp']);
  });

  test('buildSplitQuestionRecord rejects an unanalyzed sibling', () {
    final source = QuestionRecord.draft(
      id: 'root-2',
      imagePath: '/tmp/root.jpg',
      subject: Subject.math,
      recognizedText: '整题文本',
    ).copyWith(
      aiTags: const <String>['一元二次'],
      aiKnowledgePoints: const <String>['平方根'],
      analysisResult: const AnalysisResult(
        finalAnswer: '第一题答案',
        steps: <String>['第一题步骤'],
        aiTags: <String>['一元二次'],
        knowledgePoints: <String>['平方根'],
        mistakeReason: '第一题错因',
        studyAdvice: '第一题建议',
      ),
      splitResult: const QuestionSplitResult(
        sourceText: '1. 第一题\n2. 第二题',
        strategy: QuestionSplitStrategy.numbered,
        candidates: <QuestionSplitCandidate>[
          QuestionSplitCandidate(
            id: 'candidate-0',
            order: 1,
            text: '1. 第一题',
            strategy: QuestionSplitStrategy.numbered,
          ),
          QuestionSplitCandidate(
            id: 'candidate-1',
            order: 2,
            text: '2. 若 \\(\\frac{a}{b}=2\\) 且 \\(a+b=9\\)，求 \\(a,b\\)。',
            strategy: QuestionSplitStrategy.numbered,
          ),
        ],
      ),
      candidateAnalyses: const <CandidateAnalysisSnapshot>[
        CandidateAnalysisSnapshot(
          candidateId: 'candidate-0',
          order: 1,
          questionText: '1. 第一题',
          analysisResult: AnalysisResult(
            finalAnswer: '第一题答案',
            steps: <String>['第一题步骤'],
            aiTags: <String>['一元二次'],
            knowledgePoints: <String>['平方根'],
            mistakeReason: '第一题错因',
            studyAdvice: '第一题建议',
          ),
        ),
      ],
    );

    expect(
      () => buildSplitQuestionRecord(
        source: source,
        draft: const QuestionSplitDraft(
          id: 'candidate-1',
          text: '2. 若 \\(\\frac{a}{b}=2\\) 且 \\(a+b=9\\)，求 \\(a,b\\)。',
          selected: true,
          originalOrder: 2,
        ),
        sortOrder: 2,
      ),
      throwsStateError,
    );
  });

  test('buildQuestionBatchGroups groups siblings and sorts by split order', () {
    QuestionRecord record(String id, {String? rootId, int? splitOrder}) {
      return QuestionRecord.draft(
        id: id,
        imagePath: '',
        subject: Subject.math,
        recognizedText: id,
      ).copyWith(
        rootQuestionId: rootId,
        splitOrder: splitOrder,
      );
    }

    final groups = buildQuestionBatchGroups(<QuestionRecord>[
      record('standalone'),
      record('child-2', rootId: 'root-1', splitOrder: 2),
      record('child-1', rootId: 'root-1', splitOrder: 1),
      record('lonely-child', rootId: 'root-2', splitOrder: 1),
    ]);

    expect(groups.keys, <String>['root-1']);
    expect(groups['root-1']!.questions.map((question) => question.id).toList(),
        <String>['child-1', 'child-2']);
  });
}
