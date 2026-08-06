import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_provider_config.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

void main() {
  group('fixture regression config', () {
    test('builds single fixture case from environment', () {
      final cases = _fixtureCasesFromEnvironment(<String, String>{
        'AI_FIXTURE_IMAGE': '/tmp/example.png',
        'AI_FIXTURE_SUBJECT': 'math',
        'AI_FIXTURE_TEXT': '请识别这道数学题。',
      }, useDartDefines: false);

      expect(cases, hasLength(1));
      expect(cases.single.id, 'example');
      expect(cases.single.imagePath, '/tmp/example.png');
      expect(cases.single.subject, 'math');
      expect(cases.single.prompt, '请识别这道数学题。');
    });

    test('preserves an explicitly empty text hint', () {
      final cases = _fixtureCasesFromEnvironment(<String, String>{
        'AI_FIXTURE_IMAGE': '/tmp/example.png',
        'AI_FIXTURE_SUBJECT': 'unknown',
        'AI_FIXTURE_TEXT': '',
      }, useDartDefines: false);

      expect(cases, hasLength(1));
      expect(cases.single.subject, 'unknown');
      expect(cases.single.prompt, isEmpty);
    });

    test('reads complete answer term groups from environment', () {
      final cases = _fixtureCasesFromEnvironment(<String, String>{
        'AI_FIXTURE_IMAGE': '/tmp/example.png',
        'AI_FIXTURE_EXPECT_ANSWER_TERM_GROUPS':
            '条件不足;5.6,1.5,100',
      }, useDartDefines: false);

      expect(cases.single.acceptedAnswerTermGroups, <List<String>>[
        <String>['条件不足'],
        <String>['5.6', '1.5', '100'],
      ]);
    });

    test('builds default local batch fixture cases', () {
      final cases = _fixtureCasesFromEnvironment(
        const <String, String>{'AI_FIXTURE_SET': 'local'},
        fixtureRoot: 'test/fixtures',
        useDartDefines: false,
      );

      expect(cases.map((fixture) => fixture.id), contains('semicircle'));
      expect(cases.map((fixture) => fixture.id), contains('shuxue-jihe'));
      expect(cases.map((fixture) => fixture.id), contains('duoti'));
      expect(cases.map((fixture) => fixture.id), contains('wuli-dianzu'));
      expect(cases.map((fixture) => fixture.id), contains('yuwen'));
      expect(cases.map((fixture) => fixture.id), contains('yingyu'));
      expect(cases.map((fixture) => fixture.id), contains('huaxue'));
      expect(
          cases.map((fixture) => fixture.id), contains('gaokao-shuxue-2026'));
      expect(
        cases.singleWhere((fixture) => fixture.id == 'wuli-dianzu').subject,
        'physics',
      );
      expect(
        cases.singleWhere((fixture) => fixture.id == 'huaxue').subject,
        'chemistry',
      );
    });

    test('builds explicit json batch fixture cases', () {
      final cases = _fixtureCasesFromEnvironment(<String, String>{
        'AI_FIXTURE_CASES': jsonEncode(<Map<String, String>>[
          <String, String>{
            'id': 'case-a',
            'image': '/tmp/a.png',
            'subject': 'math',
            'text': '题目 A',
          },
          <String, String>{
            'image': '/tmp/b.png',
            'subject': 'english',
            'text': '题目 B',
          },
        ]),
      }, useDartDefines: false);

      expect(cases, hasLength(2));
      expect(cases.first.id, 'case-a');
      expect(cases.last.id, 'b');
      expect(cases.last.subject, 'english');
      expect(cases.last.prompt, '题目 B');
    });

    test('reads extraction fixture mode flags from environment', () {
      const environment = <String, String>{
        'AI_FIXTURE_MODE': 'extract',
        'AI_FIXTURE_EXPECT_SINGLE': 'true',
        'AI_FIXTURE_EXPECT_MULTI': 'false',
      };

      expect(_fixtureModeFromEnvironment(environment), _FixtureRunMode.extract);
      expect(_envFlag(environment, 'AI_FIXTURE_EXPECT_SINGLE'), isTrue);
      expect(_envFlag(environment, 'AI_FIXTURE_EXPECT_MULTI'), isFalse);
    });

    test('reads expected extraction subject from environment', () {
      expect(
        _expectedExtractionSubjectFromEnvironment(
          const <String, String>{'AI_FIXTURE_EXPECT_SUBJECT': 'math'},
        ),
        Subject.math,
      );
    });

    test('reads fixture run count from environment', () {
      expect(
        _fixtureRunCountFromEnvironment(
          const <String, String>{'AI_FIXTURE_RUNS': '3'},
        ),
        3,
      );
      expect(
        _fixtureRunCountFromEnvironment(const <String, String>{}),
        1,
      );
    });

    test('rejects invalid fixture run count', () {
      expect(
        () => _fixtureRunCountFromEnvironment(
          const <String, String>{'AI_FIXTURE_RUNS': '0'},
        ),
        throwsA(isA<TestFailure>()),
      );
    });

    test('reads full fixture mode from environment', () {
      expect(
        _fixtureModeFromEnvironment(
          const <String, String>{'AI_FIXTURE_MODE': 'full'},
        ),
        _FixtureRunMode.full,
      );
    });

    test('reads fixture config from provided environment before dart defines',
        () {
      expect(
        _env('AI_BASE_URL', environment: const <String, String>{
          'AI_BASE_URL': 'https://example.test/v1',
        }),
        'https://example.test/v1',
      );
      expect(
        _env('UNKNOWN_FIXTURE_KEY', environment: const <String, String>{}),
        isNull,
      );
    });

    test('builds fixture performance summary', () {
      final summary = _buildPerformanceSummary(<Map<String, dynamic>>[
        <String, dynamic>{
          'phase': 'extraction',
          'durationMs': 1200,
          'fixture': <String, dynamic>{
            'id': 'case-a',
            'subject': 'math',
          },
          'qualityGate': <String, dynamic>{
            'passed': true,
            'issues': <String>[],
            'warnings': <String>['split review'],
          },
        },
        <String, dynamic>{
          'phase': 'analysis',
          'durationMs': 2300,
          'analysisUsedImage': false,
          'expectedAnalysisOnly': true,
          'analysisInputTextLength': 1800,
          'generatedExercises': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'ex-1'},
            <String, dynamic>{'id': 'ex-2'},
          ],
          'fixture': <String, dynamic>{
            'id': 'case-a',
            'subject': 'math',
          },
          'qualityGate': <String, dynamic>{
            'passed': true,
            'issues': <String>[],
            'warnings': <String>[],
          },
        },
      ]);

      expect(summary['totalDurationMs'], 3500);
      expect(summary['slowestPhaseMs'], 2300);
      expect(summary['reportCount'], 2);
      final fixture =
          (summary['fixtures'] as List).single as Map<String, dynamic>;
      expect(fixture['id'], 'case-a');
      expect(fixture['totalDurationMs'], 3500);
      expect(fixture['warningCount'], 1);
      expect(fixture['analysisUsedImage'], isFalse);
      expect(fixture['expectedAnalysisOnly'], isTrue);
      expect(fixture['generatedExercisesCount'], 2);
    });

    test('flags extraction fixture that should stay single but split', () {
      final report = _buildExtractionReport(
        const AiQuestionExtractionResult(
          extractedQuestionText: '物理选择题',
          normalizedQuestionText: '物理选择题',
          splitResult: QuestionSplitResult(
            sourceText: '物理选择题',
            strategy: QuestionSplitStrategy.numbered,
            candidates: <QuestionSplitCandidate>[
              QuestionSplitCandidate(
                id: 'candidate-1',
                order: 1,
                text: 'A. 选项一',
                strategy: QuestionSplitStrategy.numbered,
              ),
              QuestionSplitCandidate(
                id: 'candidate-2',
                order: 2,
                text: 'B. 选项二',
                strategy: QuestionSplitStrategy.numbered,
              ),
            ],
          ),
        ),
        expectSingleCandidate: true,
        expectMultipleCandidates: false,
      );

      final gate = report['qualityGate'] as Map<String, dynamic>;
      expect(gate['passed'], isFalse);
      expect(
        gate['issues'],
        contains('expected one composite question, got 2 split candidates'),
      );
    });

    test('flags extraction fixture that should split but stayed single', () {
      final report = _buildExtractionReport(
        const AiQuestionExtractionResult(
          extractedQuestionText: '1. 第一题\n2. 第二题',
          normalizedQuestionText: '1. 第一题\n2. 第二题',
          splitResult: QuestionSplitResult(
            sourceText: '1. 第一题\n2. 第二题',
            strategy: QuestionSplitStrategy.fallback,
            candidates: <QuestionSplitCandidate>[
              QuestionSplitCandidate(
                id: 'candidate-1',
                order: 1,
                text: '1. 第一题\n2. 第二题',
                strategy: QuestionSplitStrategy.fallback,
              ),
            ],
          ),
        ),
        expectSingleCandidate: false,
        expectMultipleCandidates: true,
      );

      final gate = report['qualityGate'] as Map<String, dynamic>;
      expect(gate['passed'], isFalse);
      expect(
        gate['issues'],
        contains('expected multiple independent questions, got 1 candidate'),
      );
    });

    test('flags analysis-only fixture that still returned exercises', () {
      final gate = _evaluateQualityGate(
        AnalysisResult(
          subject: Subject.chinese,
          finalAnswer: '陶渊明',
          finalAnswerDerivation: '图片内容为《桃花源记》文常题，作者是陶渊明。',
          reconstructedQuestionText: '《桃花源记》文常积累。',
          steps: const <String>[
            '识别题目为《桃花源记》文学常识。',
            '最终答案为陶渊明。',
          ],
          aiTags: const <String>['桃花源记', '文学常识'],
          knowledgePoints: const <String>['陶渊明，名潜，字元亮。'],
          mistakeReason: '',
          studyAdvice: '',
        ),
        <GeneratedExercise>[
          _generatedExercise(
            id: 'e1',
            question: '下列对《桃花源记》作者判断正确的是哪一项？',
            explanation: '《桃花源记》的作者是陶渊明。',
          ),
        ],
        expectedAnalysisOnly: true,
      );

      expect(gate['passed'], isFalse);
      expect(
        gate['issues'],
        contains('analysis-only fixture returned generated exercises'),
      );
    });

    test('enforces fixture answer terms and manual-review expectation', () {
      final gate = _evaluateQualityGate(
        AnalysisResult(
          subject: Subject.chemistry,
          finalAnswer: '铁生锈需要水和氧气共同存在。',
          finalAnswerDerivation: 'A 组同时接触水和氧气，锈蚀最明显。',
          reconstructedQuestionText: '探究铁生锈条件。',
          steps: const <String>[
            '比较 A、B、C 三组实验条件。',
            '得出铁生锈需要水和氧气共同存在。',
          ],
          aiTags: const <String>['铁锈蚀'],
          knowledgePoints: const <String>['控制变量法'],
          mistakeReason: '',
          studyAdvice: '',
          consistencyStatus: AnalysisConsistencyStatus.needsReview,
          consistencyNote: 'B 组是否隔绝氧气需结合原题核对。',
        ),
        const <GeneratedExercise>[],
        requiredAnswerTerms: const <String>['水和氧气'],
        expectNeedsManualReview: true,
      );

      expect(gate['passed'], isTrue);
    });

    test('flags a missing fixture answer term', () {
      final gate = _evaluateQualityGate(
        AnalysisResult(
          subject: Subject.chemistry,
          finalAnswer: '正确答案为 C。',
          finalAnswerDerivation: '根据纯净物定义判断。',
          reconstructedQuestionText: '下列物质中，属于纯净物的是。',
          steps: const <String>[
            '空气和自来水属于混合物。',
            '因此选择 C。',
          ],
          aiTags: const <String>['纯净物'],
          knowledgePoints: const <String>['物质分类'],
          mistakeReason: '',
          studyAdvice: '',
        ),
        const <GeneratedExercise>[],
        requiredAnswerTerms: const <String>['氧化铁'],
      );

      expect(gate['passed'], isFalse);
      expect(gate['issues'], contains('missing required answer term: 氧化铁'));
    });

    test('accepts any configured safe uncertainty conclusion', () {
      final gate = _evaluateQualityGate(
        AnalysisResult(
          subject: Subject.chemistry,
          finalAnswer: '题目信息不足，无法唯一确定。',
          finalAnswerDerivation: '未知量多于独立方程。',
          reconstructedQuestionText: '化学计算题。',
          steps: const <String>[
            '列出质量守恒关系。',
            '因此无法唯一确定结果。',
          ],
          aiTags: const <String>['信息不足'],
          knowledgePoints: const <String>['质量守恒'],
          mistakeReason: '',
          studyAdvice: '',
          consistencyStatus: AnalysisConsistencyStatus.needsReview,
          consistencyNote: '题干关键条件需核对。',
        ),
        const <GeneratedExercise>[],
        acceptableAnswerTerms: const <String>[
          '条件不足',
          '信息不足',
          '无法唯一确定',
        ],
        expectNeedsManualReview: true,
      );

      expect(gate['passed'], isTrue);
    });

    test('accepts one complete configured answer pattern', () {
      final gate = _evaluateQualityGate(
        AnalysisResult(
          subject: Subject.chemistry,
          finalAnswer: '生成氧气 5.6 g，二氧化锰约 1.5 g，分解率 100%。',
          finalAnswerDerivation: '按常规题意，将 15.8 g 视为混合物总质量。',
          reconstructedQuestionText: '化学计算题。',
          steps: const <String>[
            '固体质量差为 5.6 g。',
            '二氧化锰质量约为 1.5 g，分解率为 100%。',
          ],
          aiTags: const <String>['质量守恒'],
          knowledgePoints: const <String>['化学方程式计算'],
          mistakeReason: '',
          studyAdvice: '',
          consistencyStatus: AnalysisConsistencyStatus.needsReview,
          consistencyNote: '15.8 g 指代的对象需核对。',
        ),
        const <GeneratedExercise>[],
        acceptedAnswerTermGroups: const <List<String>>[
          <String>['条件不足'],
          <String>['信息不足'],
          <String>['无法唯一确定'],
          <String>['5.6', '1.5', '100'],
        ],
        expectNeedsManualReview: true,
      );

      expect(gate['passed'], isTrue);
    });

    test('flags advanced proof exercises drifting to function substitution',
        () {
      final gate = _evaluateQualityGate(
        AnalysisResult(
          finalAnswer: '（1）\\(D(-1)=(0,\\frac{3}{2})\\)；（2）证明成立；（3）证明单调递增。',
          finalAnswerDerivation: '利用 \\(D(x_0)\\) 的定义、集合包含关系和单调性证明。',
          reconstructedQuestionText:
              '已知函数定义域为 \\(\\mathbb{R}\\)，定义集合 \\(D(x_0)\\)。证明 \\(D(x_2)\\subseteq D(x_1)\\)，并证明单调递增。',
          steps: const <String>[
            '根据 \\(D(x_0)\\) 的定义讨论集合包含关系。',
            '任取 \\(0<a<b\\)，证明 \\(f(a)<f(b)\\)。',
          ],
          aiTags: const <String>['函数', '集合包含', '单调性'],
          knowledgePoints: const <String>['抽象函数证明'],
          mistakeReason: '',
          studyAdvice: '',
          consistencyStatus: AnalysisConsistencyStatus.consistent,
        ),
        <GeneratedExercise>[
          _generatedExercise(
            id: 'e1',
            question: '已知函数 \\(f(x)=2x+1\\)，求 \\(f(3)\\) 的值。',
            explanation: '把 \\(x=3\\) 代入，得 \\(f(3)=7\\)。',
          ),
          _generatedExercise(
            id: 'e2',
            question: '已知函数 \\(g(x)=x^2-2x\\)，求 \\(g(4)\\) 的值。',
            explanation: '把 \\(x=4\\) 代入，得 \\(g(4)=8\\)。',
          ),
        ],
      );

      expect(gate['passed'], isFalse);
      expect(
        gate['issues'],
        contains('advanced math proof generated exercises drifted to '
            'function-value substitution'),
      );
    });

    test('flags physics circuit exercises drifting to generic algebra', () {
      final gate = _evaluateQualityGate(
        AnalysisResult(
          subject: Subject.physics,
          finalAnswer: '应先判断电路连接方式，再根据欧姆定律分析电表示数。',
          finalAnswerDerivation:
              '电流表示数、电压表示数与电阻变化有关，需结合 \\(I=\\frac{U}{R}\\) 和串并联电路规律判断。',
          reconstructedQuestionText:
              '如图所示电路中，电源电压保持不变，闭合开关后根据电压表、电流表示数变化判断正确选项。',
          steps: const <String>[
            '先识别电流路径和电表测量对象。',
            '再根据欧姆定律和串并联电路规律分析选项。',
          ],
          aiTags: const <String>['电路', '欧姆定律', '串并联电路'],
          knowledgePoints: const <String>['欧姆定律', '电表示数变化'],
          mistakeReason: '',
          studyAdvice: '',
        ),
        <GeneratedExercise>[
          _generatedExercise(
            id: 'e1',
            question: 'x+1=4，求 x 的值',
            explanation: '移项得 x=4-1=3。',
          ),
          _generatedExercise(
            id: 'e2',
            question: '2x=8，求 x 的值',
            explanation: '两边同时除以 2 得 x=4。',
          ),
        ],
      );

      expect(gate['passed'], isFalse);
      expect(
        gate['issues'],
        contains(
            'physics circuit generated exercises drifted to generic algebra'),
      );
    });

    test('flags unreliable advanced proof note hidden behind consistent status',
        () {
      final gate = _evaluateQualityGate(
        AnalysisResult(
          finalAnswer: '（1）\\(D(-1)=(0,\\frac{3}{2})\\)；（2）证明成立；（3）证明单调递增。',
          finalAnswerDerivation: '利用 \\(D(x_0)\\) 的定义、集合包含关系和单调性证明。',
          reconstructedQuestionText:
              '已知函数定义域为 \\(\\mathbb{R}\\)，定义集合 \\(D(x_0)\\)。证明 \\(D(x_2)\\subseteq D(x_1)\\)，并证明单调递增。',
          steps: const <String>[
            '根据 \\(D(x_0)\\) 的定义讨论集合包含关系。',
            '标准构造如下，但这里缺少严格包含关系证明，存在逻辑跳步。',
          ],
          aiTags: const <String>['函数', '集合包含', '单调性'],
          knowledgePoints: const <String>['抽象函数证明'],
          mistakeReason: '',
          studyAdvice: '',
          consistencyStatus: AnalysisConsistencyStatus.consistent,
          consistencyNote:
              'finalAnswer 一致，但第（3）问证明链存在明显问题，构造不稳定，缺少严格证明，需要人工复核。',
        ),
        <GeneratedExercise>[
          _generatedExercise(
            id: 'e1',
            question: '已知抽象函数满足 \\(D(x_2)\\subseteq D(x_1)\\)。证明其在给定区间上的单调性。',
            explanation: '围绕 \\(D(x_0)\\) 的定义构造增量并证明集合包含关系。',
          ),
        ],
      );

      expect(gate['passed'], isFalse);
      expect(
        gate['issues'],
        contains('advanced math proof is marked consistent but proof audit '
            'reports unreliable reasoning'),
      );
    });

    test('flags language analysis that failed to recognize source question',
        () {
      final gate = _evaluateQualityGate(
        AnalysisResult(
          subject: Subject.chinese,
          finalAnswer: '无法确定',
          finalAnswerDerivation: '由于当前未提供具体语文题目或图片内容，无法得出题目要求的最终答案。',
          reconstructedQuestionText: '当前输入未提供可识别的图片内容或具体语文题干，因此无法还原原题。',
          visualAssumptions: const VisualAssumptions(
            needsManualReview: true,
            reviewReason: '缺少图片或具体题目文本，无法判断题型、正确答案和错因。',
          ),
          visualAssumptionStatus: VisualAssumptionStatus.needsReview,
          consistencyStatus: AnalysisConsistencyStatus.needsReview,
          consistencyNote: '缺少图片或具体题目文本，无法判断题型、正确答案和错因。',
          steps: const <String>[
            '当前只有分析任务说明，没有原题正文。',
            '最终结论：无法确定',
          ],
          aiTags: const <String>['语文'],
          knowledgePoints: const <String>['题干识别'],
          mistakeReason: '没有具体题目内容。',
          studyAdvice: '需要重新识别图片。',
        ),
        <GeneratedExercise>[
          _generatedExercise(
            id: 'e1',
            question: 'x+1=4，求 x 的值',
            explanation: '移项得 x=4-1=3',
          ),
        ],
      );

      expect(gate['passed'], isFalse);
      expect(
        gate['issues'],
        contains('language analysis failed to recognize source question'),
      );
      expect(
        gate['issues'],
        contains('language generated exercises drifted to generic algebra'),
      );
    });

    test('flags placeholder language generated exercises', () {
      final gate = _evaluateQualityGate(
        AnalysisResult(
          subject: Subject.english,
          finalAnswer: '无法确定',
          finalAnswerDerivation: '由于未提供图片或具体英语题干，无法确定题目的最终答案。',
          reconstructedQuestionText: '当前未提供可识别的图片内容或具体英语题干，因此无法还原完整题目。',
          visualAssumptions: const VisualAssumptions(
            targetObject: '未提供图片',
            targetQuestion: '无法确认题目具体要求',
            needsManualReview: true,
            reviewReason: '缺少图片或题目文本，无法识别原题并判断正确答案',
          ),
          visualAssumptionStatus: VisualAssumptionStatus.needsReview,
          consistencyStatus: AnalysisConsistencyStatus.needsReview,
          consistencyNote: '缺少图片或题目文本，无法识别原题并判断正确答案',
          steps: const <String>[
            '没有可识别的英语题目图片或文本。',
            '因此本题最终答案为：无法确定。',
          ],
          aiTags: const <String>['英语'],
          knowledgePoints: const <String>['题干识别'],
          mistakeReason: '缺少原题内容。',
          studyAdvice: '需要重新识别图片。',
        ),
        <GeneratedExercise>[
          _generatedExercise(
            id: 'e1',
            question: '因原题图片或文本缺失，以下为占位练习：Choose the correct sentence.',
            explanation: '主语 She 是第三人称单数，一般现在时谓语动词应用第三人称单数形式 goes。',
          ),
        ],
      );

      expect(gate['passed'], isFalse);
      expect(
        gate['issues'],
        contains('language analysis failed to recognize source question'),
      );
      expect(
        gate['issues'],
        contains('language generated exercises are placeholders'),
      );
    });
  });

  test('analyzes a local image fixture with app AI service', () async {
    final fixtureCases = _fixtureCasesFromEnvironment(Platform.environment);
    if (fixtureCases.isEmpty) {
      markTestSkipped(
        'Set AI_FIXTURE_IMAGE, AI_FIXTURE_CASES, or AI_FIXTURE_SET=local '
        'to run local image regression.',
      );
      return;
    }

    final environment = Platform.environment;
    final config = _readConfigFromEnvironment(environment);
    final mode = _fixtureModeFromEnvironment(environment);
    final expectSingleCandidate =
        _envFlag(environment, 'AI_FIXTURE_EXPECT_SINGLE');
    final expectMultipleCandidates =
        _envFlag(environment, 'AI_FIXTURE_EXPECT_MULTI');
    final expectedExtractionSubject =
        _expectedExtractionSubjectFromEnvironment(environment);
    final fixtureRunCount = _fixtureRunCountFromEnvironment(environment);
    final service = AiAnalysisService(
      settingsRepository: _ToolSettingsRepository(config),
    );

    final reports = <Map<String, dynamic>>[];
    for (final fixture in fixtureCases) {
      final imageFile = File(fixture.imagePath);
      expect(
        imageFile.existsSync(),
        isTrue,
        reason: 'Image file must exist for fixture ${fixture.id}.',
      );

      for (var runIndex = 1; runIndex <= fixtureRunCount; runIndex++) {
        // ignore: avoid_print
        print(
          '\n[TEST] fixture: ${fixture.id}'
          '${fixtureRunCount > 1 ? ' (run $runIndex/$fixtureRunCount)' : ''}',
        );

        if (mode == _FixtureRunMode.extract || mode == _FixtureRunMode.full) {
          final extractionTimer = Stopwatch()..start();
          final extraction = await service.extractQuestionStructure(
            subjectName: fixture.subject,
            imagePath: imageFile.path,
            textHint: fixture.prompt,
          );
          extractionTimer.stop();
          final report = _buildExtractionReport(
            extraction,
            expectSingleCandidate: expectSingleCandidate,
            expectMultipleCandidates: expectMultipleCandidates,
            expectedSubject: expectedExtractionSubject,
          )
            ..['fixture'] = fixture.toJson()
            ..['phase'] = 'extraction'
            ..['runIndex'] = runIndex
            ..['runCount'] = fixtureRunCount
            ..['durationMs'] = extractionTimer.elapsedMilliseconds
            ..['imageBytes'] = imageFile.lengthSync()
            ..['textHintLength'] = fixture.prompt.length;
          reports.add(report);

          const encoder = JsonEncoder.withIndent('  ');
          // ignore: avoid_print
          print(encoder.convert(report));

          final qualityGate = report['qualityGate']! as Map<String, dynamic>;
          expect(
            qualityGate['passed'],
            isTrue,
            reason:
                'Fixture ${fixture.id} run $runIndex/$fixtureRunCount: ${(qualityGate['issues'] as List).join('\n')}',
          );
          if (mode == _FixtureRunMode.extract) continue;

          final normalizedText =
              extraction.normalizedQuestionText.trim().isNotEmpty
                  ? extraction.normalizedQuestionText
                  : extraction.extractedQuestionText;
          final analysisFixture = extraction.subject != null &&
                  extraction.subject != Subject.unknown
              ? fixture.withSubject(extraction.subject!)
              : fixture;
          await _runAnalysisFixture(
            service: service,
            fixture: analysisFixture,
            correctedText: normalizedText,
            imagePath: null,
            reports: reports,
          );
          continue;
        }

        await _runAnalysisFixture(
          service: service,
          fixture: fixture,
          correctedText: fixture.prompt,
          imagePath: imageFile.path,
          reports: reports,
        );
      }
    }

    // ignore: avoid_print
    print(
        '\n[TEST] fixture summary: ${reports.length} fixture(s) passed gate.');
    // ignore: avoid_print
    print('[TEST] performance summary:');
    const encoder = JsonEncoder.withIndent('  ');
    // ignore: avoid_print
    print(encoder.convert(_buildPerformanceSummary(reports)));
  }, timeout: const Timeout(Duration(minutes: 5)));
}

enum _FixtureRunMode { analysis, extract, full }

class _FixtureCase {
  const _FixtureCase({
    required this.id,
    required this.imagePath,
    required this.subject,
    required this.prompt,
    this.requiredAnswerTerms = const <String>[],
    this.acceptableAnswerTerms = const <String>[],
    this.acceptedAnswerTermGroups = const <List<String>>[],
    this.expectNeedsManualReview,
  });

  final String id;
  final String imagePath;
  final String subject;
  final String prompt;
  final List<String> requiredAnswerTerms;
  final List<String> acceptableAnswerTerms;
  final List<List<String>> acceptedAnswerTermGroups;
  final bool? expectNeedsManualReview;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'imagePath': imagePath,
        'subject': subject,
        'prompt': prompt,
        if (requiredAnswerTerms.isNotEmpty)
          'requiredAnswerTerms': requiredAnswerTerms,
        if (acceptableAnswerTerms.isNotEmpty)
          'acceptableAnswerTerms': acceptableAnswerTerms,
        if (acceptedAnswerTermGroups.isNotEmpty)
          'acceptedAnswerTermGroups': acceptedAnswerTermGroups,
        if (expectNeedsManualReview != null)
          'expectNeedsManualReview': expectNeedsManualReview,
      };

  _FixtureCase withSubject(Subject value) {
    return _FixtureCase(
      id: id,
      imagePath: imagePath,
      subject: value.name,
      prompt: prompt,
      requiredAnswerTerms: requiredAnswerTerms,
      acceptableAnswerTerms: acceptableAnswerTerms,
      acceptedAnswerTermGroups: acceptedAnswerTermGroups,
      expectNeedsManualReview: expectNeedsManualReview,
    );
  }
}

List<_FixtureCase> _fixtureCasesFromEnvironment(
  Map<String, String> environment, {
  String fixtureRoot = 'test/fixtures',
  bool useDartDefines = true,
}) {
  final rawCases = _env(
    'AI_FIXTURE_CASES',
    environment: environment,
    useDartDefines: useDartDefines,
  )?.trim();
  if (rawCases != null && rawCases.isNotEmpty) {
    final decoded = jsonDecode(rawCases);
    if (decoded is! List) {
      fail('AI_FIXTURE_CASES must be a JSON array.');
    }
    return decoded
        .whereType<Map>()
        .map((item) => _fixtureCaseFromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  final imagePath = _env(
    'AI_FIXTURE_IMAGE',
    environment: environment,
    useDartDefines: useDartDefines,
  )?.trim();
  if (imagePath != null && imagePath.isNotEmpty) {
    final subject = _env(
      'AI_FIXTURE_SUBJECT',
      environment: environment,
      useDartDefines: useDartDefines,
    )?.trim();
    final prompt = _fixtureTextHintFromEnvironment(
      environment,
      useDartDefines: useDartDefines,
    );
    return <_FixtureCase>[
      _FixtureCase(
        id: _fixtureIdFromPath(imagePath),
        imagePath: imagePath,
        subject: subject?.isNotEmpty == true ? subject! : 'math',
        prompt: prompt ?? '请根据图片识别题目并解答。',
        requiredAnswerTerms: _answerTermsFromEnvironment(
          environment,
          useDartDefines: useDartDefines,
        ),
        acceptableAnswerTerms: _acceptableAnswerTermsFromEnvironment(
          environment,
          useDartDefines: useDartDefines,
        ),
        acceptedAnswerTermGroups: _acceptedAnswerTermGroupsFromEnvironment(
          environment,
          useDartDefines: useDartDefines,
        ),
        expectNeedsManualReview: _manualReviewExpectationFromEnvironment(
          environment,
          useDartDefines: useDartDefines,
        ),
      ),
    ];
  }

  if (_env(
        'AI_FIXTURE_SET',
        environment: environment,
        useDartDefines: useDartDefines,
      )?.trim().toLowerCase() ==
      'local') {
    return _defaultLocalFixtureCases(fixtureRoot);
  }

  return const <_FixtureCase>[];
}

String? _fixtureTextHintFromEnvironment(
  Map<String, String> environment, {
  required bool useDartDefines,
}) {
  if (environment.containsKey('AI_FIXTURE_TEXT')) {
    return environment['AI_FIXTURE_TEXT'] ?? '';
  }
  if (!useDartDefines) return null;

  final defined = _dartDefine('AI_FIXTURE_TEXT');
  return defined.isNotEmpty ? defined : null;
}

_FixtureRunMode _fixtureModeFromEnvironment(Map<String, String> environment) {
  final rawMode =
      _env('AI_FIXTURE_MODE', environment: environment)?.trim().toLowerCase();
  switch (rawMode) {
    case null:
    case '':
    case 'analysis':
    case 'analyze':
      return _FixtureRunMode.analysis;
    case 'extract':
    case 'ocr':
      return _FixtureRunMode.extract;
    case 'full':
    case 'pipeline':
      return _FixtureRunMode.full;
    default:
      fail('AI_FIXTURE_MODE must be analysis, extract, or full.');
  }
}

Future<void> _runAnalysisFixture({
  required AiAnalysisService service,
  required _FixtureCase fixture,
  required String correctedText,
  required String? imagePath,
  required List<Map<String, dynamic>> reports,
}) async {
  final analysisTimer = Stopwatch()..start();
  final result = await service.analyzeExtractedQuestion(
    correctedText: correctedText,
    subjectName: fixture.subject,
    imagePath: imagePath,
  );
  analysisTimer.stop();
  // ignore: avoid_print
  print(
      '[TEST] result type: ${result.runtimeType}, isParsed: ${result is ParsedAnalysisResult}');
  final generatedExercises = result is ParsedAnalysisResult
      ? service.extractGeneratedExercisesFromContent(
          result.rawContent,
          questionId: fixture.id,
          analysis: result,
          sourceQuestionText: correctedText,
        )
      : service.extractGeneratedExercises(
          result,
          questionId: fixture.id,
          sourceQuestionText: correctedText,
        );
  // ignore: avoid_print
  print('[TEST] generatedExercises count: ${generatedExercises.length}');
  for (final ex in generatedExercises) {
    // ignore: avoid_print
    print(
        '[TEST] exercise: ${ex.id}, hasDiagram: ${ex.diagramData != null}, q: ${ex.question.substring(0, ex.question.length.clamp(0, 40))}');
  }

  final expectedAnalysisOnly = _expectsAnalysisOnlyFixture(
    fixture,
    correctedText: correctedText,
    imagePath: imagePath,
  );
  if (expectedAnalysisOnly) {
    // ignore: avoid_print
    print('[TEST] expectedAnalysisOnly: true');
  }

  final report = _buildReport(
    result,
    generatedExercises,
    expectedAnalysisOnly: expectedAnalysisOnly,
    requiredAnswerTerms: fixture.requiredAnswerTerms,
    acceptableAnswerTerms: fixture.acceptableAnswerTerms,
    acceptedAnswerTermGroups: fixture.acceptedAnswerTermGroups,
    expectNeedsManualReview: fixture.expectNeedsManualReview,
  )
    ..['fixture'] = fixture.toJson()
    ..['phase'] = 'analysis'
    ..['durationMs'] = analysisTimer.elapsedMilliseconds
    ..['expectedAnalysisOnly'] = expectedAnalysisOnly
    ..['analysisInputTextLength'] = correctedText.length
    ..['analysisUsedImage'] = imagePath != null
    ..['imageBytes'] = imagePath != null && File(imagePath).existsSync()
        ? File(imagePath).lengthSync()
        : 0;
  reports.add(report);

  const encoder = JsonEncoder.withIndent('  ');
  // ignore: avoid_print
  print(encoder.convert(report));

  final qualityGate = report['qualityGate']! as Map<String, dynamic>;
  final warnings = qualityGate['warnings'] as List;
  if (warnings.isNotEmpty) {
    // ignore: avoid_print
    print('\n⚠️  WARNINGS (needs manual review, not a test failure):');
    for (final w in warnings) {
      // ignore: avoid_print
      print('  - $w');
    }
  }

  expect(
    qualityGate['passed'],
    isTrue,
    reason:
        'Fixture ${fixture.id}: ${(qualityGate['issues'] as List).join('\n')}',
  );
}

Map<String, dynamic> _buildPerformanceSummary(
  List<Map<String, dynamic>> reports,
) {
  final fixturesById = <String, Map<String, dynamic>>{};
  var totalDurationMs = 0;
  var slowestPhaseMs = 0;

  for (final report in reports) {
    final fixture = (report['fixture'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final id = fixture['id']?.toString() ?? 'unknown';
    final phase = report['phase']?.toString() ?? 'unknown';
    final durationMs = report['durationMs'] is int
        ? report['durationMs'] as int
        : int.tryParse(report['durationMs']?.toString() ?? '') ?? 0;
    final qualityGate =
        (report['qualityGate'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    final issues = qualityGate['issues'] is List
        ? qualityGate['issues'] as List
        : const <dynamic>[];
    final warnings = qualityGate['warnings'] is List
        ? qualityGate['warnings'] as List
        : const <dynamic>[];

    totalDurationMs += durationMs;
    if (durationMs > slowestPhaseMs) slowestPhaseMs = durationMs;

    final fixtureSummary = fixturesById.putIfAbsent(
      id,
      () => <String, dynamic>{
        'id': id,
        'subject': fixture['subject'],
        'totalDurationMs': 0,
        'phaseCount': 0,
        'issueCount': 0,
        'warningCount': 0,
        'analysisUsedImage': false,
        'expectedAnalysisOnly': false,
        'analysisInputTextLength': 0,
        'generatedExercisesCount': 0,
        'phases': <String, dynamic>{},
      },
    );

    fixtureSummary['totalDurationMs'] =
        (fixtureSummary['totalDurationMs'] as int) + durationMs;
    fixtureSummary['phaseCount'] = (fixtureSummary['phaseCount'] as int) + 1;
    fixtureSummary['issueCount'] =
        (fixtureSummary['issueCount'] as int) + issues.length;
    fixtureSummary['warningCount'] =
        (fixtureSummary['warningCount'] as int) + warnings.length;

    if (report['analysisUsedImage'] == true) {
      fixtureSummary['analysisUsedImage'] = true;
    }
    if (report['expectedAnalysisOnly'] == true) {
      fixtureSummary['expectedAnalysisOnly'] = true;
    }
    final inputLength = report['analysisInputTextLength'];
    if (inputLength is int) {
      fixtureSummary['analysisInputTextLength'] = inputLength;
    }
    final generatedExercises = report['generatedExercises'];
    if (generatedExercises is List) {
      fixtureSummary['generatedExercisesCount'] = generatedExercises.length;
    }

    final phases = fixtureSummary['phases'] as Map<String, dynamic>;
    phases[phase] = <String, dynamic>{
      'durationMs': durationMs,
      'passed': qualityGate['passed'] == true,
      'issues': issues.length,
      'warnings': warnings.length,
      if (report.containsKey('analysisUsedImage'))
        'usedImage': report['analysisUsedImage'] == true,
      if (report.containsKey('expectedAnalysisOnly'))
        'expectedAnalysisOnly': report['expectedAnalysisOnly'] == true,
      if (report.containsKey('analysisInputTextLength'))
        'inputTextLength': report['analysisInputTextLength'],
      if (report.containsKey('textHintLength'))
        'textHintLength': report['textHintLength'],
      if (report.containsKey('imageBytes')) 'imageBytes': report['imageBytes'],
    };
  }

  final fixtures = fixturesById.values.toList()
    ..sort((a, b) =>
        (b['totalDurationMs'] as int).compareTo(a['totalDurationMs'] as int));

  return <String, dynamic>{
    'reportCount': reports.length,
    'fixtureCount': fixtures.length,
    'totalDurationMs': totalDurationMs,
    'slowestPhaseMs': slowestPhaseMs,
    'fixtures': fixtures,
  };
}

bool _envFlag(Map<String, String> environment, String key) {
  final raw = _env(key, environment: environment)?.trim().toLowerCase();
  return raw == '1' || raw == 'true' || raw == 'yes' || raw == 'y';
}

int _fixtureRunCountFromEnvironment(Map<String, String> environment) {
  final raw = _env('AI_FIXTURE_RUNS', environment: environment)?.trim();
  if (raw == null || raw.isEmpty) return 1;

  final count = int.tryParse(raw);
  if (count == null || count < 1 || count > 5) {
    fail('AI_FIXTURE_RUNS must be an integer from 1 to 5.');
  }
  return count;
}

Subject? _expectedExtractionSubjectFromEnvironment(
  Map<String, String> environment,
) {
  final raw = _env('AI_FIXTURE_EXPECT_SUBJECT', environment: environment)
      ?.trim()
      .toLowerCase();
  if (raw == null || raw.isEmpty) return null;
  for (final subject in Subject.values) {
    if (subject.name == raw || subject.label == raw) return subject;
  }
  fail('AI_FIXTURE_EXPECT_SUBJECT must be a valid subject name.');
}

_FixtureCase _fixtureCaseFromMap(Map<String, dynamic> item) {
  final image = (item['image'] ?? item['imagePath'])?.toString().trim() ?? '';
  if (image.isEmpty) fail('Each AI_FIXTURE_CASES item must include image.');
  final hasExplicitText =
      item.containsKey('text') || item.containsKey('prompt');
  final text = (item['text'] ?? item['prompt'])?.toString() ?? '';
  return _FixtureCase(
    id: item['id']?.toString().trim().isNotEmpty == true
        ? item['id'].toString().trim()
        : _fixtureIdFromPath(image),
    imagePath: image,
    subject: item['subject']?.toString().trim().isNotEmpty == true
        ? item['subject'].toString().trim()
        : 'math',
    prompt: hasExplicitText ? text : '请根据图片识别题目并解答。',
    requiredAnswerTerms: _stringList(item['requiredAnswerTerms']),
    acceptableAnswerTerms: _stringList(item['acceptableAnswerTerms']),
    acceptedAnswerTermGroups: _stringListGroups(
      item['acceptedAnswerTermGroups'],
    ),
    expectNeedsManualReview: _nullableBool(item['expectNeedsManualReview']),
  );
}

List<String> _answerTermsFromEnvironment(
  Map<String, String> environment, {
  required bool useDartDefines,
}) {
  final raw = _env(
    'AI_FIXTURE_EXPECT_ANSWER_TERMS',
    environment: environment,
    useDartDefines: useDartDefines,
  );
  return _stringList(raw);
}

List<String> _acceptableAnswerTermsFromEnvironment(
  Map<String, String> environment, {
  required bool useDartDefines,
}) {
  final raw = _env(
    'AI_FIXTURE_EXPECT_ANY_ANSWER_TERMS',
    environment: environment,
    useDartDefines: useDartDefines,
  );
  return _stringList(raw);
}

List<List<String>> _acceptedAnswerTermGroupsFromEnvironment(
  Map<String, String> environment, {
  required bool useDartDefines,
}) {
  final raw = _env(
    'AI_FIXTURE_EXPECT_ANSWER_TERM_GROUPS',
    environment: environment,
    useDartDefines: useDartDefines,
  );
  return _stringListGroups(raw);
}

bool? _manualReviewExpectationFromEnvironment(
  Map<String, String> environment, {
  required bool useDartDefines,
}) {
  return _nullableBool(_env(
    'AI_FIXTURE_EXPECT_NEEDS_MANUAL_REVIEW',
    environment: environment,
    useDartDefines: useDartDefines,
  ));
}

List<String> _stringList(Object? value) {
  final values = switch (value) {
    List<Object?>() => value,
    String() => value.split(','),
    null => const <Object?>[],
    _ => <Object?>[value],
  };
  return values
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList(growable: false);
}

List<List<String>> _stringListGroups(Object? value) {
  final rawGroups = switch (value) {
    List<Object?>() => value,
    String() => value.split(';'),
    null => const <Object?>[],
    _ => <Object?>[value],
  };
  return rawGroups
      .map(_stringList)
      .where((group) => group.isNotEmpty)
      .toList(growable: false);
}

bool? _nullableBool(Object? value) {
  if (value == null) return null;
  if (value is bool) return value;
  switch (value.toString().trim().toLowerCase()) {
    case '1':
    case 'true':
    case 'yes':
    case 'y':
      return true;
    case '0':
    case 'false':
    case 'no':
    case 'n':
      return false;
    default:
      fail('Expected a boolean fixture value, got: $value');
  }
}

List<_FixtureCase> _defaultLocalFixtureCases(String fixtureRoot) {
  String path(String name) => '$fixtureRoot/$name';
  return <_FixtureCase>[
    _FixtureCase(
      id: 'semicircle',
      imagePath: path('semicircle.png'),
      subject: 'math',
      prompt: '图中标注上边为3、底边为7、右边高为10，图内为半圆，求图中括号所示区域面积。',
    ),
    _FixtureCase(
      id: 'shuxue-jihe',
      imagePath: path('shuxue-jihe.png'),
      subject: 'math',
      prompt:
          '请识别图片中的数学几何题，整理完整题干；若需要读图推断，请标出不确定项，并生成同题型举一反三练习，图形题练习应包含 diagramData。',
    ),
    _FixtureCase(
      id: 'duoti',
      imagePath: path('duoti.png'),
      subject: 'math',
      prompt: '请识别图片中的所有题目，按题号分别整理题干并分析；如果图片包含多道题，请不要只分析其中一道。',
    ),
    _FixtureCase(
      id: 'wuli-dianzu',
      imagePath: path('wuli-dianzu.png'),
      subject: 'physics',
      prompt: '请识别图片中的物理电学题，整理题干并分析电阻/电路关系，给出最终答案和举一反三练习。',
    ),
    _FixtureCase(
      id: 'yuwen',
      imagePath: path('yuwen.png'),
      subject: 'chinese',
      prompt: '请识别图片中的语文题，整理完整题干并分析作答思路，生成同题型举一反三练习。',
    ),
    _FixtureCase(
      id: 'yingyu',
      imagePath: path('yingyu.png'),
      subject: 'english',
      prompt: '请识别图片中的英语题，整理完整题干并分析作答思路，生成同题型举一反三练习。',
    ),
    _FixtureCase(
      id: 'huaxue',
      imagePath: path('huaxue.jpg'),
      subject: 'chemistry',
      prompt:
          '请识别图片中的高二化学有机合成综合题，保持为一道大题处理，不要把（1）到（7）误拆成独立题；整理题干、分析作答思路，并生成同题型举一反三练习。',
    ),
    _FixtureCase(
      id: 'gaokao-shuxue-2026',
      imagePath: path('gaokao-shuxue-2026.jpg'),
      subject: 'math',
      prompt: '请识别图片中的 2026 年高考数学第 19 题，保持（1）（2）（3）为同一道综合题处理，整理完整题干并给出严谨证明。',
    ),
  ];
}

String _fixtureIdFromPath(String imagePath) {
  final normalized = imagePath.replaceAll('\\', '/');
  final filename = normalized.split('/').last;
  final dot = filename.lastIndexOf('.');
  return dot > 0 ? filename.substring(0, dot) : filename;
}

AiProviderConfig _readConfigFromEnvironment(Map<String, String> environment) {
  final baseUrl = _env('AI_BASE_URL', environment: environment);
  final apiKey = _env('AI_API_KEY', environment: environment);
  final model = _env('AI_MODEL', environment: environment);

  final missing = <String>[
    if (baseUrl == null || baseUrl.trim().isEmpty) 'AI_BASE_URL',
    if (apiKey == null || apiKey.trim().isEmpty) 'AI_API_KEY',
    if (model == null || model.trim().isEmpty) 'AI_MODEL',
  ];
  if (missing.isNotEmpty) {
    fail('Missing environment variables: ${missing.join(', ')}.');
  }

  return AiProviderConfig(
    id: 'tool-env',
    displayName: 'Tool Environment',
    baseUrl: baseUrl!.trim(),
    model: model!.trim(),
    apiKey: apiKey!.trim(),
  );
}

Map<String, dynamic> _buildExtractionReport(
  AiQuestionExtractionResult extraction, {
  required bool expectSingleCandidate,
  required bool expectMultipleCandidates,
  Subject? expectedSubject,
}) {
  final splitResult = extraction.splitResult;
  final extractedText = extraction.extractedQuestionText.trim();
  final normalizedText = extraction.normalizedQuestionText.trim();
  final primaryText =
      normalizedText.isNotEmpty ? normalizedText : extractedText;
  final issues = <String>[];
  final warnings = <String>[];

  if (primaryText.isEmpty) {
    issues.add('extraction returned empty question text');
  }
  if (expectedSubject != null && extraction.subject != expectedSubject) {
    issues.add(
      'expected extracted subject ${expectedSubject.name}, got ${extraction.subject?.name ?? 'unknown'}',
    );
  }
  if (splitResult == null || splitResult.candidates.isEmpty) {
    issues.add('extraction returned no split candidates');
  }
  if (expectSingleCandidate && (splitResult?.hasMultipleCandidates ?? false)) {
    issues.add(
      'expected one composite question, got ${splitResult!.candidates.length} split candidates',
    );
  }
  if (expectMultipleCandidates &&
      !(splitResult?.hasMultipleCandidates ?? false)) {
    issues.add(
      'expected multiple independent questions, got ${splitResult?.candidates.length ?? 0} candidate',
    );
  }

  if (splitResult != null && splitResult.hasMultipleCandidates) {
    warnings.add(
      'splitResult has ${splitResult.candidates.length} candidates; verify whether this is a real multi-question image',
    );
  }

  return <String, dynamic>{
    'subject': extraction.subject?.name,
    'extractedQuestionText': extractedText,
    'normalizedQuestionText': normalizedText,
    'splitResult': splitResult?.toJson(),
    'qualityGate': <String, dynamic>{
      'passed': issues.isEmpty,
      'issues': issues,
      'warnings': warnings,
    },
  };
}

Map<String, dynamic> _buildReport(
  AnalysisResult result,
  List<GeneratedExercise> generatedExercises, {
  bool expectedAnalysisOnly = false,
  List<String> requiredAnswerTerms = const <String>[],
  List<String> acceptableAnswerTerms = const <String>[],
  List<List<String>> acceptedAnswerTermGroups = const <List<String>>[],
  bool? expectNeedsManualReview,
}) {
  return <String, dynamic>{
    'finalAnswer': result.finalAnswer,
    'finalAnswerDerivation': result.finalAnswerDerivation,
    'steps': result.steps,
    'visualAssumptions': result.visualAssumptions?.toJson(),
    'visualAssumptionStatus': result.visualAssumptionStatus.name,
    'consistencyStatus': result.consistencyStatus.name,
    'consistencyNote': result.consistencyNote,
    'wasVerifierUsed': result.wasVerifierUsed,
    'generatedExercises': generatedExercises
        .map((exercise) => <String, dynamic>{
              'id': exercise.id,
              'difficulty': exercise.difficulty,
              'question': exercise.question,
              'options': exercise.options,
              'answer': exercise.answer,
              'explanation': exercise.explanation,
            })
        .toList(),
    'qualityGate': _evaluateQualityGate(
      result,
      generatedExercises,
      expectedAnalysisOnly: expectedAnalysisOnly,
      requiredAnswerTerms: requiredAnswerTerms,
      acceptableAnswerTerms: acceptableAnswerTerms,
      acceptedAnswerTermGroups: acceptedAnswerTermGroups,
      expectNeedsManualReview: expectNeedsManualReview,
    ),
  };
}

Map<String, dynamic> _evaluateQualityGate(
  AnalysisResult result,
  List<GeneratedExercise> generatedExercises, {
  bool expectedAnalysisOnly = false,
  List<String> requiredAnswerTerms = const <String>[],
  List<String> acceptableAnswerTerms = const <String>[],
  List<List<String>> acceptedAnswerTermGroups = const <List<String>>[],
  bool? expectNeedsManualReview,
}) {
  final issues = <String>[];
  final warnings = <String>[];
  final finalAnswerTokens = _extractConclusionTokens(result.finalAnswer);
  final derivationTokens =
      _extractConclusionTokens(result.finalAnswerDerivation);
  final stepTokens = <String>{
    for (final step in result.steps.reversed.take(2))
      ..._extractConclusionTokens(step),
  };

  if (result.finalAnswer.trim().isEmpty) {
    issues.add('finalAnswer is empty');
  }
  if (result.steps.isEmpty) {
    issues.add('steps is empty');
  }
  if (expectedAnalysisOnly && generatedExercises.isNotEmpty) {
    issues.add('analysis-only fixture returned generated exercises');
  }

  final answerEvidence = <String>[
    result.finalAnswer,
    result.finalAnswerDerivation,
    ...result.steps,
  ].join('\n').replaceAll(RegExp(r'\s+'), '').toLowerCase();
  for (final term in requiredAnswerTerms) {
    final normalizedTerm = term.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    if (normalizedTerm.isNotEmpty && !answerEvidence.contains(normalizedTerm)) {
      issues.add('missing required answer term: $term');
    }
  }
  final hasAcceptedTerm = acceptableAnswerTerms.any((term) {
    final normalizedTerm = term.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    return normalizedTerm.isNotEmpty && answerEvidence.contains(normalizedTerm);
  });
  final hasAcceptedTermGroup = acceptedAnswerTermGroups.any((group) {
    return group.isNotEmpty &&
        group.every((term) {
          final normalizedTerm =
              term.replaceAll(RegExp(r'\s+'), '').toLowerCase();
          return normalizedTerm.isNotEmpty && answerEvidence.contains(normalizedTerm);
        });
  });
  if (acceptableAnswerTerms.isNotEmpty || acceptedAnswerTermGroups.isNotEmpty) {
    if (!hasAcceptedTerm && !hasAcceptedTermGroup) {
      final acceptedPatterns = <String>[
        if (acceptableAnswerTerms.isNotEmpty)
          acceptableAnswerTerms.join(' | '),
        ...acceptedAnswerTermGroups.map((group) => group.join(' & ')),
      ];
      issues.add(
        'missing an accepted answer pattern: ${acceptedPatterns.join(' | ')}',
      );
    }
  }

  if (expectNeedsManualReview != null) {
    final actuallyNeedsManualReview =
        result.consistencyStatus == AnalysisConsistencyStatus.needsReview ||
            result.visualAssumptionStatus == VisualAssumptionStatus.needsReview;
    if (actuallyNeedsManualReview != expectNeedsManualReview) {
      issues.add(
        'expected needsManualReview=$expectNeedsManualReview, '
        'got $actuallyNeedsManualReview',
      );
    }
  }

  final hasAnswerStepConflict = finalAnswerTokens.isNotEmpty &&
      stepTokens.isNotEmpty &&
      finalAnswerTokens.intersection(stepTokens).isEmpty;
  if (hasAnswerStepConflict) {
    issues.add(
      'finalAnswer conflicts with final steps: '
      '${finalAnswerTokens.join(', ')} vs ${stepTokens.join(', ')}',
    );
  }

  final hasAnswerDerivationConflict = finalAnswerTokens.isNotEmpty &&
      derivationTokens.isNotEmpty &&
      finalAnswerTokens.intersection(derivationTokens).isEmpty;
  if (hasAnswerDerivationConflict) {
    issues.add(
      'finalAnswer conflicts with finalAnswerDerivation: '
      '${finalAnswerTokens.join(', ')} vs ${derivationTokens.join(', ')}',
    );
  }

  final answerFamily = <String>{
    ...finalAnswerTokens,
    ...derivationTokens,
    ...stepTokens,
  }.where(_isHighRiskPiAreaAnswer).toSet();
  if (answerFamily.length > 1) {
    issues.add(
      'multiple high-risk area answers appear: ${answerFamily.join(', ')}',
    );
  }

  if (result.visualAssumptionStatus == VisualAssumptionStatus.needsReview &&
      result.consistencyStatus != AnalysisConsistencyStatus.needsReview) {
    issues.add(
        'visual assumptions need review but consistencyStatus is not needsReview');
  }

  // needsReview with internally consistent results is a warning, not a failure.
  // The App will correctly show "可能解法/需核对" — this is the desired behavior
  // for image-based geometry problems where label interpretation is uncertain.
  if (result.consistencyStatus == AnalysisConsistencyStatus.needsReview) {
    final isInternallyConsistent =
        !hasAnswerStepConflict && !hasAnswerDerivationConflict;
    if (isInternallyConsistent) {
      warnings.add(
          'analysis needs manual review (App will show 可能解法): ${result.consistencyNote}');
    } else {
      issues.add(
          'analysis requires manual review with internal conflicts: ${result.consistencyNote}');
    }
  }

  for (final exercise in generatedExercises) {
    if (_hasGeneratedExerciseSelfInvalidation(exercise)) {
      issues.add('generated exercise self-invalidates: ${exercise.id}');
    }
  }
  if (_isOrganicChemistryAnalysis(result)) {
    final exerciseText = generatedExercises
        .map((exercise) =>
            '${exercise.question} ${exercise.explanation} ${exercise.options?.join(' ') ?? ''}')
        .join(' ');
    if (_hasGenericAlgebraExerciseDrift(exerciseText)) {
      issues.add(
          'organic chemistry generated exercises drifted to generic algebra');
    } else if (!_hasOrganicChemistryExerciseSignal(exerciseText)) {
      issues.add(
          'organic chemistry generated exercises do not match chemistry topic');
    }
  }
  if (_isAdvancedMathProofAnalysis(result)) {
    final proofAuditText =
        '${result.consistencyNote} ${result.steps.join(' ')}';
    if (result.consistencyStatus == AnalysisConsistencyStatus.consistent &&
        _hasUnreliableAdvancedProofAuditSignal(proofAuditText)) {
      issues.add('advanced math proof is marked consistent but proof audit '
          'reports unreliable reasoning');
    }

    final exerciseText = generatedExercises
        .map((exercise) =>
            '${exercise.question} ${exercise.explanation} ${exercise.options?.join(' ') ?? ''}')
        .join(' ');
    if (generatedExercises.isNotEmpty &&
        _hasFunctionValueSubstitutionExerciseDrift(exerciseText) &&
        !_hasAdvancedMathProofExerciseSignal(exerciseText)) {
      issues.add('advanced math proof generated exercises drifted to '
          'function-value substitution');
    }
  }
  if (_isPhysicsCircuitAnalysis(result)) {
    final exerciseText = generatedExercises
        .map((exercise) =>
            '${exercise.question} ${exercise.explanation} ${exercise.options?.join(' ') ?? ''}')
        .join(' ');
    if (_hasGenericAlgebraExerciseDrift(exerciseText)) {
      issues.add(
          'physics circuit generated exercises drifted to generic algebra');
    } else if (generatedExercises.isNotEmpty &&
        !_hasPhysicsCircuitExerciseSignal(exerciseText)) {
      issues.add(
          'physics circuit generated exercises do not match circuit topic');
    }
  }
  if (_isLanguageAnalysis(result)) {
    if (_hasMissingSourceLanguageSignal(result)) {
      issues.add('language analysis failed to recognize source question');
    }

    final exerciseText = generatedExercises
        .map((exercise) =>
            '${exercise.question} ${exercise.explanation} ${exercise.options?.join(' ') ?? ''}')
        .join(' ');
    if (_hasLanguagePlaceholderExerciseSignal(exerciseText)) {
      issues.add('language generated exercises are placeholders');
    }
    if (_hasGenericAlgebraExerciseDrift(exerciseText)) {
      issues.add('language generated exercises drifted to generic algebra');
    }
  }

  return <String, dynamic>{
    'passed': issues.isEmpty,
    'issues': issues,
    'warnings': warnings,
    'finalAnswerTokens': finalAnswerTokens.toList(),
    'derivationTokens': derivationTokens.toList(),
    'stepConclusionTokens': stepTokens.toList(),
  };
}

Set<String> _extractConclusionTokens(String text) {
  final normalized = text
      .replaceAll('\\(', ' ')
      .replaceAll('\\)', ' ')
      .replaceAll('\\[', ' ')
      .replaceAll('\\]', ' ')
      .replaceAll('π', r'\pi')
      .replaceAll(' ', '')
      .toLowerCase();
  final tokens = <String>{};

  for (final match in RegExp(r'[a-z][\.、:]?').allMatches(normalized)) {
    final token = match.group(0)!.replaceAll(RegExp(r'[\.、:]'), '');
    if (token.length == 1) tokens.add(token.toUpperCase());
  }

  for (final match
      in RegExp(r'\\frac\{([^{}]+)\}\{([^{}]+)\}').allMatches(normalized)) {
    tokens.add('${match.group(1)!}/${match.group(2)!}');
  }

  for (final match in RegExp(
    r'\d+(?:\.\d+)?(?:\\pi|pi)?(?:/\d+(?:\.\d+)?)?|(?:\\pi|pi)(?:/\d+(?:\.\d+)?)?',
  ).allMatches(normalized)) {
    final token = match.group(0)!;
    if (RegExp(r'\d|\\pi|pi').hasMatch(token)) {
      tokens.add(token.replaceAll('pi', r'\pi'));
    }
  }

  return tokens.where((token) => token.isNotEmpty).toSet();
}

bool _hasGeneratedExerciseSelfInvalidation(GeneratedExercise exercise) {
  final text =
      '${exercise.question} ${exercise.explanation} ${exercise.options?.join(' ') ?? ''}';
  return <String>[
    '选项中没有',
    '没有该值',
    '无正确选项',
    '选项设计不严谨',
    '选项有误',
    '原选项设计',
    '需重新检查',
    '需要重新检查',
    '修正后应',
    '应为修正',
    '无法从选项',
    '题目不严谨',
    '本题无解',
  ].any(text.contains);
}

GeneratedExercise _generatedExercise({
  required String id,
  required String question,
  required String explanation,
}) {
  return GeneratedExercise(
    id: id,
    questionId: 'fixture-question',
    generationMode: ExerciseGenerationMode.practice,
    difficulty: '同级',
    question: question,
    answer: 'A',
    explanation: explanation,
    createdAt: DateTime(2026),
    options: const <String>['A. 正确', 'B. 错误'],
  );
}

bool _isOrganicChemistryAnalysis(AnalysisResult result) {
  final text = <String>[
    result.subject?.name ?? '',
    result.subject?.label ?? '',
    result.reconstructedQuestionText,
    result.finalAnswer,
    result.finalAnswerDerivation,
    ...result.steps,
    ...result.aiTags,
    ...result.knowledgePoints,
    result.mistakeReason,
    result.studyAdvice,
  ].join(' ').toLowerCase();
  final hasChemistry = text.contains('化学') || text.contains('chemistry');
  final hasOrganic = <String>[
    '有机',
    '合成路线',
    '苯',
    '官能团',
    '结构简式',
    '同分异构',
    'fries',
    'beckmann',
    'nh2oh',
  ].any(text.contains);
  return hasChemistry && hasOrganic;
}

bool _hasGenericAlgebraExerciseDrift(String text) {
  final normalized = text.replaceAll(' ', '').toLowerCase();
  return normalized.contains('x+1=4') ||
      normalized.contains('2x=8') ||
      normalized.contains('3x+2=11') ||
      normalized.contains('求x的值') && !normalized.contains('化学');
}

bool _hasOrganicChemistryExerciseSignal(String text) {
  final normalized = text.toLowerCase();
  return <String>[
    '苯',
    '酚',
    '酯',
    '醛',
    '酮',
    '羟基',
    '银镜',
    '核磁',
    'fries',
    'beckmann',
    'nh2oh',
    '官能团',
    '有机',
  ].any(normalized.contains);
}

bool _isAdvancedMathProofAnalysis(AnalysisResult result) {
  final text = <String>[
    result.subject?.name ?? '',
    result.subject?.label ?? '',
    result.reconstructedQuestionText,
    result.finalAnswer,
    result.finalAnswerDerivation,
    ...result.steps,
    ...result.aiTags,
    ...result.knowledgePoints,
    result.mistakeReason,
    result.studyAdvice,
  ].join(' ').toLowerCase();
  final hasMathSignal = result.subject == Subject.math ||
      text.contains('数学') ||
      text.contains('函数') ||
      text.contains(r'\mathbb') ||
      text.contains('单调');
  final hasProofSignal = text.contains('证明') ||
      text.contains('证得') ||
      text.contains('任取') ||
      text.contains('严格证明');
  final hasAdvancedSignal = text.contains('d(x') ||
      text.contains(r'\subseteq') ||
      text.contains('集合包含') ||
      (text.contains('定义域') && text.contains('单调')) ||
      text.contains('抽象函数');
  return hasMathSignal && hasProofSignal && hasAdvancedSignal;
}

bool _hasUnreliableAdvancedProofAuditSignal(String text) {
  final normalized = text.replaceAll(' ', '').toLowerCase();
  final hasUnreliableSignal = <String>[
    '证明链存在明显问题',
    '证明不可靠',
    '构造不稳定',
    '不能直接推出',
    '缺少严格',
    '逻辑跳步',
    '需要人工复核',
    '需人工复核',
  ].any(normalized.contains);
  final hasProofContext = normalized.contains('证明') ||
      normalized.contains('单调') ||
      normalized.contains('d(x') ||
      normalized.contains(r'\subseteq');
  return hasUnreliableSignal && hasProofContext;
}

bool _isPhysicsCircuitAnalysis(AnalysisResult result) {
  final text = <String>[
    result.subject?.name ?? '',
    result.subject?.label ?? '',
    result.reconstructedQuestionText,
    result.finalAnswer,
    result.finalAnswerDerivation,
    ...result.steps,
    ...result.aiTags,
    ...result.knowledgePoints,
    result.mistakeReason,
    result.studyAdvice,
  ].join(' ').toLowerCase();
  final hasPhysics = result.subject == Subject.physics ||
      text.contains('物理') ||
      text.contains('physics');
  final hasCircuit = <String>[
    '电路',
    '电流',
    '电压',
    '电阻',
    '欧姆',
    '串联',
    '并联',
    r'\frac{u}{r}',
  ].any(text.contains);
  return hasPhysics && hasCircuit;
}

bool _hasPhysicsCircuitExerciseSignal(String text) {
  final normalized = text.toLowerCase();
  return <String>[
    '电路',
    '电流',
    '电压',
    '电阻',
    '欧姆',
    '串联',
    '并联',
    '电表',
    '滑动变阻器',
    r'i=',
    r'\frac{u}{r}',
  ].any(normalized.contains);
}

bool _isLanguageAnalysis(AnalysisResult result) {
  final text = <String>[
    result.subject?.name ?? '',
    result.subject?.label ?? '',
    result.reconstructedQuestionText,
    ...result.aiTags,
    ...result.knowledgePoints,
  ].join(' ').toLowerCase();
  return result.subject == Subject.chinese ||
      result.subject == Subject.english ||
      text.contains('语文') ||
      text.contains('英语') ||
      text.contains('chinese') ||
      text.contains('english');
}

bool _hasMissingSourceLanguageSignal(AnalysisResult result) {
  final text = <String>[
    result.reconstructedQuestionText,
    result.finalAnswer,
    result.finalAnswerDerivation,
    ...result.steps,
    result.visualAssumptions?.targetObject ?? '',
    result.visualAssumptions?.targetQuestion ?? '',
    result.visualAssumptions?.reviewReason ?? '',
    ...?result.visualAssumptions?.solutionBasis,
    ...?result.visualAssumptions?.uncertainItems,
    result.consistencyNote,
    result.mistakeReason,
    result.studyAdvice,
  ].join(' ').replaceAll(' ', '').toLowerCase();
  final hasMissingSourceSignal = <String>[
    '缺少图片',
    '未提供图片',
    '图片或文本缺失',
    '未提供可识别',
    '没有可识别',
    '缺少原题',
    '题干未知',
    '原题题干',
    '无法识别原题',
    '无法还原原题',
    '无法还原完整题目',
    '无法判断题型',
  ].any(text.contains);
  final hasFailureConclusion = text.contains('无法确定') || text.contains('无法确认');
  return hasMissingSourceSignal && hasFailureConclusion;
}

bool _hasLanguagePlaceholderExerciseSignal(String text) {
  final normalized = text.replaceAll(' ', '').toLowerCase();
  return <String>[
    '占位练习',
    '以下为占位',
    '原题图片或文本缺失',
    '原题题型未知',
    '因原题',
    '题型未知',
  ].any(normalized.contains);
}

bool _expectsAnalysisOnlyFixture(
  _FixtureCase fixture, {
  required String correctedText,
  required String? imagePath,
}) {
  if (imagePath == null || imagePath.isEmpty) return false;
  final subject = fixture.subject.trim().toLowerCase();
  final isLanguage = subject == 'chinese' ||
      subject == 'english' ||
      subject == '语文' ||
      subject == '英语';
  if (!isLanguage) return false;
  return _looksLikeInstructionOnlyText(correctedText.trim());
}

bool _looksLikeInstructionOnlyText(String text) {
  if (text.isEmpty) return false;
  final hasInstructionVerb =
      RegExp(r'请识别|整理题干|分析作答|生成同题型|不要把|保持为').hasMatch(text);
  final hasConcreteQuestionSignal =
      RegExp(r'^\s*\d+[\.、]|（\d+）|\(\d+\)|已知|求|证明|解方程|选择|填空').hasMatch(text);
  return hasInstructionVerb && !hasConcreteQuestionSignal;
}

bool _hasFunctionValueSubstitutionExerciseDrift(String text) {
  final normalized = text.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  final substitutionCount = RegExp(
    r'求(?:\\\()?[fgh]\(\d+\)(?:\\\))?的值|函数值|代入(?:，|,)?得',
  ).allMatches(normalized).length;
  final routineFunctionTemplateSignals = <String>[
    '已知函数',
    '求f(',
    '求g(',
    '求h(',
    '把x=',
  ].where(normalized.contains).length;
  return substitutionCount >= 2 || routineFunctionTemplateSignals >= 3;
}

bool _hasAdvancedMathProofExerciseSignal(String text) {
  final normalized = text.toLowerCase();
  return <String>[
    '证明',
    '单调',
    'd(x',
    r'\subseteq',
    '集合',
    '任取',
    '定义域',
    '抽象函数',
  ].any(normalized.contains);
}

bool _isHighRiskPiAreaAnswer(String token) {
  final normalized = token.replaceAll(' ', '').replaceAll('pi', r'\pi');
  return normalized == r'25\pi' ||
      normalized == r'25\pi/2' ||
      normalized == r'29\pi/2' ||
      normalized == r'25\pi}{2' ||
      normalized == r'29\pi}{2';
}

String? _env(
  String key, {
  Map<String, String>? environment,
  bool useDartDefines = true,
}) {
  final value =
      environment != null ? environment[key] : Platform.environment[key];
  if (value != null && value.trim().isNotEmpty) return value;
  if (!useDartDefines) return null;
  final defined = _dartDefine(key);
  return defined.trim().isNotEmpty ? defined : null;
}

String _dartDefine(String key) {
  switch (key) {
    case 'AI_BASE_URL':
      return const String.fromEnvironment('AI_BASE_URL');
    case 'AI_API_KEY':
      return const String.fromEnvironment('AI_API_KEY');
    case 'AI_MODEL':
      return const String.fromEnvironment('AI_MODEL');
    case 'AI_FIXTURE_IMAGE':
      return const String.fromEnvironment('AI_FIXTURE_IMAGE');
    case 'AI_FIXTURE_SUBJECT':
      return const String.fromEnvironment('AI_FIXTURE_SUBJECT');
    case 'AI_FIXTURE_TEXT':
      return const String.fromEnvironment('AI_FIXTURE_TEXT');
    case 'AI_FIXTURE_SET':
      return const String.fromEnvironment('AI_FIXTURE_SET');
    case 'AI_FIXTURE_CASES':
      return const String.fromEnvironment('AI_FIXTURE_CASES');
    case 'AI_FIXTURE_MODE':
      return const String.fromEnvironment('AI_FIXTURE_MODE');
    case 'AI_FIXTURE_EXPECT_SINGLE':
      return const String.fromEnvironment('AI_FIXTURE_EXPECT_SINGLE');
    case 'AI_FIXTURE_EXPECT_MULTI':
      return const String.fromEnvironment('AI_FIXTURE_EXPECT_MULTI');
    case 'AI_FIXTURE_EXPECT_SUBJECT':
      return const String.fromEnvironment('AI_FIXTURE_EXPECT_SUBJECT');
    case 'AI_FIXTURE_RUNS':
      return const String.fromEnvironment('AI_FIXTURE_RUNS');
  }
  return '';
}

class _ToolSettingsRepository implements SettingsRepository {
  _ToolSettingsRepository(this._config);

  AiProviderConfig _config;
  final Map<String, String> _strings = <String, String>{};

  @override
  Future<AiProviderConfig?> getAiProviderConfig() async => _config;

  @override
  Future<void> saveAiProviderConfig(AiProviderConfig config) async {
    _config = config;
  }

  @override
  Future<String?> getString(String key) async => _strings[key];

  @override
  Future<void> setString(String key, String value) async {
    _strings[key] = value;
  }
}
