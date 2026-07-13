import React, { useState } from "react";
import type { TabsProps } from "antd";
import { Avatar, Col, Layout, Row, Tabs } from "antd";
import "normalize.css";
import "./App.scss";
import { Outlet, useLocation, useNavigate } from "react-router-dom";

// 搜索框

const Search = ({ searchType }: { searchType: string }) => {
  let placeholder,
    isSearchNeeded = true;
  switch (searchType) {
    case "/":
      placeholder = "搜索些什么";
      break;
    case "/my":
      placeholder = "搜我的文章";
      break;
    case "/publish":
      isSearchNeeded = false;
      break;
    default:
      placeholder = "搜索些什么";
  }

  const [isActive, setIsActive] = useState(false);

  const handleFocus = () => {
    setIsActive(true);
  };

  const handleBlur = () => {
    setIsActive(false);
  };

  const handleSubmit = (e: { preventDefault: () => void }) => {
    e.preventDefault();
    console.log("Search triggered");
  };

  if (!isSearchNeeded) {
    return <></>;
  }

  return (
    <div
      className={`search-container ${isActive ? "active" : ""}`}
      onBlur={handleBlur}
      onFocus={handleFocus}
    >
      <form className="search-form" autoComplete="off" onSubmit={handleSubmit}>
        <input type="text" placeholder={placeholder} className="search-input" />
      </form>
      <button className="search-button">
        <img
          src="./src/assets/icons/search.svg"
          alt="Search"
          className="search-icon"
        />
      </button>
    </div>
  );
};

const { Header, Content, Footer } = Layout;

const items: TabsProps["items"] = [
  {
    key: "/",
    label: "首页",
  },
  {
    key: "/my",
    label: "我的",
  },
  {
    key: "/publish",
    label: "发布",
  },
];

const App: React.FC = () => {
  // 页面切换
  const navigate = useNavigate();

  const handleNavChange = (key: string) => {
    navigate(key);
  };

  // 标签高亮
  const location = useLocation();
  const selectedKey = location.pathname;
  console.log(selectedKey);

  let userName, userAvatar;

  return (
    <Layout style={{ minHeight: "100vh" }}>
      <Header
        style={{
          padding: "0px",
          display: "flex",
          alignItems: "center",
          position: "sticky",
          zIndex: 1,
          top: 0,
        }}
      >
        <Row style={{ width: "100%" }}>
          <Col flex="none">
            <div className="logo">
              <img src="./src/assets/logo.png" alt="logo" />
              <span>迷梦Blog</span>
            </div>
          </Col>
          <Col flex="none">
            <Tabs
              className="navigation"
              activeKey={selectedKey}
              items={items}
              onChange={handleNavChange}
            />
          </Col>
          <Col
            flex="auto"
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <Search searchType={selectedKey} />
          </Col>
          <Col flex="none">
            <span className="user">{userName ? userName : "未登录"} </span>
            <Avatar
              style={{ marginRight: "16px", marginLeft: "8px" }}
              src={userAvatar ? userAvatar : "./src/assets/avatar.png"}
              size="large"
            />
          </Col>
        </Row>
      </Header>
      <Content
        style={{
          padding: "0 16px",
          maxWidth: "1200px",
        }}
      >
        <Outlet />
      </Content>
      <Footer style={{ textAlign: "center" }}>
        MengChen © {new Date().getFullYear()} Created by MiMeng Studio
      </Footer>
    </Layout>
  );
};

export default App;
