from typing import List, Dict, Any
from pydantic import BaseModel, ConfigDict, Field

class DashboardSummaryCards(BaseModel):
    model_config = ConfigDict(extra="ignore")

    totalLeads: int = 0
    activeClients: int = 0
    activeProjects: int = 0
    pendingFollowUps: int = 0
    totalRevenue: float = 0.0
    collectedRevenue: float = 0.0
    pendingPayments: float = 0.0

class DashboardStatsResponse(BaseModel):
    model_config = ConfigDict(extra="ignore")

    summary: DashboardSummaryCards
    todayFollowUps: List[Dict[str, Any]] = Field(default_factory=list)
    tasksDueToday: List[Dict[str, Any]] = Field(default_factory=list)
    recentProjectUpdates: List[Dict[str, Any]] = Field(default_factory=list)
    recentPayments: List[Dict[str, Any]] = Field(default_factory=list)
    recentMessages: List[Dict[str, Any]] = Field(default_factory=list)
