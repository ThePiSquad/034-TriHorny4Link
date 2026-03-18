extends Node2D

enum TutorialStep {
	STEP_0_ENEMY_ATTACK,      # 步骤0：敌人攻击
	STEP_1_PLACE_CRYSTAL,      # 步骤1：放置圆形（水晶）
	STEP_2_CONNECT_CONDUIT,     # 步骤2：连接矩形（导管）
	STEP_3_PLACE_TURRET,       # 步骤3：放置炮塔
	STEP_4_COLOR_MIXING,        # 步骤4：颜色混色演示
	STEP_5_ENEMY_INTRODUCTION,  # 步骤5：敌人介绍
	STEP_6_TEST_DEFENSE,        # 步骤6：测试防御
	COMPLETED
}

enum TutorialState {
	DEMONSTRATION,  # 演示状态
	INTERACTION,     # 交互状态
	WAITING,         # 等待状态
	COMPLETED        # 完成状态
}
