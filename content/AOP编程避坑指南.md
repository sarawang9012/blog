# AOP 编程避坑指南

## 前言


---

## 1. Spring AOP 的代理限制

### 1.1 只能拦截 Spring 管理的 Bean

AOP 只对 Spring 容器管理的 Bean 生效。手动 `new` 出来的对象不会被拦截。

```java
// ❌ 不会生效：new 出来的对象不受 Spring 管理
CommonApiServiceImpl service = new CommonApiServiceImpl();
service.smsSend(dto, request);

// ✅ 会生效：通过 @Autowired 注入的 Bean
@Autowired
private CommonApiService commonApiService;
commonApiService.smsSend(dto, request);
```

### 1.2 同类内部调用不会触发切面

Spring AOP 基于动态代理，同类内部调用走的是 `this` 引用，不经过代理对象。

```java
@Service
public class SomeService {
    public void methodA() {
        // ❌ 不会触发切面！因为这是 this.methodB() 调用
        this.methodB();
    }
    
    // 假设 methodB 被切面拦截
    public void methodB() { ... }
}
```

**解决方案：**
- 避免在同类内部调用需要被切面拦截的方法
- 或者通过 `AopContext.currentProxy()` 获取代理对象来调用（需配置 `exposeProxy=true`）

---

## 2. 切入点表达式错误

### 2.1 常见错误

```java
// ❌ 包名写错，切面不会生效
@Pointcut("execution(* io.renren.modules.open.service.CommonApiServiceImpl.smsSend(..))")
// 实际包是 service.impl，不是 service

// ❌ 方法名拼写错误
@Pointcut("execution(* ...smsSned(..))")

// ✅ 正确写法：包名、类名、方法名必须完全匹配
@Pointcut("execution(* io.renren.modules.open.service.impl.CommonApiServiceImpl.smsSend(..))")
```

### 2.2 验证切入点是否生效

在切面方法开头加日志，确认是否被调用：

```java
@Around("smsSendPointcut()")
public Object aroundSmsSend(ProceedingJoinPoint joinPoint) {
    log.info("切面生效了！方法: {}", joinPoint.getSignature());
    // ... 后续逻辑
}
```

---

## 3. 参数提取的坑

### 3.1 不要假设参数顺序

```java
// Controller 方法参数
public Map<String, Object> smsSend(CommonApiDto dto, HttpServletRequest request)

// ❌ 错误：假设参数顺序固定
Object[] args = joinPoint.getArgs();
CommonApiDto dto = (CommonApiDto) args[0];  // 可能不是第一个！

// ✅ 正确：通过 instanceof 判断类型
Object[] args = joinPoint.getArgs();
CommonApiDto dto = null;
HttpServletRequest request = null;

for (Object arg : args) {
    if (arg instanceof CommonApiDto) {
        dto = (CommonApiDto) arg;
    } else if (arg instanceof HttpServletRequest) {
        request = (HttpServletRequest) arg;
    }
}
```

---

## 4. 异常处理的坑

### 4.1 不要吞掉原异常

```java
// ❌ 错误：捕获异常后不抛出，调用方以为成功了
@Around("smsSendPointcut()")
public Object aroundSmsSend(ProceedingJoinPoint joinPoint) {
    try {
        return joinPoint.proceed();
    } catch (Throwable e) {
        log.error("出错了", e);
        // 没有 throw e，调用方收不到异常！业务方会误以为成功
        return null;
    }
}

// ✅ 正确：异常要继续抛出
@Around("smsSendPointcut()")
public Object aroundSmsSend(ProceedingJoinPoint joinPoint) throws Throwable {
    try {
        return joinPoint.proceed();
    } catch (Throwable e) {
        throw e;  // 必须重新抛出，保证原业务逻辑不受影响
    }
}
```

### 4.2 finally 块中的异常不能影响主流程

```java
@Around("smsSendPointcut()")
public Object aroundSmsSend(ProceedingJoinPoint joinPoint) throws Throwable {
    long startTime = System.currentTimeMillis();
    Object result = null;
    Throwable throwable = null;

    try {
        result = joinPoint.proceed();
        return result;
    } catch (Throwable e) {
        throwable = e;
        throw e;
    } finally {
        try {
            // 审计逻辑放在 try-catch 中，即使失败也不影响主业务
            buildAndSaveLog(joinPoint, result, throwable, elapsed);
        } catch (Exception ex) {
            log.error("审计日志处理异常, error={}", ex.getMessage(), ex);
        }
    }
}
```

---

## 5. 性能问题

### 5.1 不要在切面内执行耗时操作

```java
// ❌ 错误：同步写入数据库，会阻塞主流程，增加请求耗时
@Around("smsSendPointcut()")
public Object aroundSmsSend(ProceedingJoinPoint joinPoint) throws Throwable {
    Object result = joinPoint.proceed();
    
    // 同步写数据库，每个请求都要等待 DB 写入完成
    smsCaptchaAuditLogDao.insert(entity);
    
    return result;
}

// ✅ 正确：异步写入，不阻塞主流程
smsCaptchaAuditLogService.saveAuditLogAsync(entity);
```

### 5.2 警惕切面内调用导致死循环

```java
// ❌ 可能导致死循环
@Around("smsSendPointcut()")
public Object aroundSmsSend(ProceedingJoinPoint joinPoint) {
    // 如果 saveAuditLog 也被同一个切面拦截，就会无限循环
    someService.saveAuditLog();
}
```

---

## 6. 多切面执行顺序

如果项目有多个切面（如日志切面 + 事务切面 + 权限切面），执行顺序可能不符合预期。

```java
@Aspect
@Order(1)  // 数字越小，优先级越高，外层先执行
public class AuditAspect { ... }

@Aspect
@Order(2)
public class LogAspect { ... }

@Aspect
@Order(3)
public class AuthAspect { ... }
```

**执行顺序：**
```
Order(1) 前置 → Order(2) 前置 → Order(3) 前置 → 目标方法 → Order(3) 后置 → Order(2) 后置 → Order(1) 后置
```

**建议：** 明确每个切面的 `@Order` 值，避免顺序混乱导致的问题。

---

## 7. 无法拦截的方法类型

Spring AOP 是**运行期**基于动态代理实现的，以下方法无法被拦截：

| 方法类型 | 能否拦截 | 原因 |
|---------|---------|------|
| `public` 方法 | ✅ 能 | 正常代理 |
| `final` 方法 | ❌ 不能 | 不能被重写 |
| `private` 方法 | ❌ 不能 | 代理类无法访问 |
| `static` 方法 | ❌ 不能 | 属于类级别，不走实例 |
| `protected` 方法 | ⚠️ 视情况 | 取决于代理方式 |

```java
public class SomeService {
    // ❌ 这些方法不会被 AOP 拦截
    public final void method1() { }
    private void method2() { }
    public static void method3() { }
}
```

---

## 8. 依赖引用问题

### 8.1 类路径错误

切面中引用的工具类或服务类，包路径必须正确。否则切面执行时会报 `ClassNotFoundException` 或编译失败。

**本项目实际案例：**

```java
// ❌ 错误：JavaAesCommonUtils 不在 common.utils 包下
import io.renren.common.utils.JavaAesCommonUtils;

// ✅ 正确：实际在 zk 子包下
import io.renren.common.utils.zk.JavaAesCommonUtils;
```

**经验：** 切面编译失败时，检查所有 import 的类是否能找到。

---

## 9. 切面不生效的排查清单

当切面不生效时，按以下顺序逐一检查：

| 检查项 | 说明 |
|-------|------|
| 1. 类是否是 Spring Bean | 是否有 `@Component`/`@Service`/`@Controller` 注解 |
| 2. 切面类是否被扫描 | 切面类所在包是否在组件扫描范围内 |
| 3. 切入点表达式是否正确 | 包名、类名、方法名是否完全匹配 |
| 4. 切面是否被调用 | 在切面方法第一行加日志确认 |
| 5. 代理是否创建 | 启动时看日志是否有 AOP 相关日志 |
| 6. 依赖是否完整 | 切面引用的类是否能找到 |
| 7. 是否被同类调用 | 同类内部调用不会触发切面 |
| 8. 方法是否是 public | private/final/static 方法无法拦截 |

---

## 10. AOP 最佳实践

### 10.1 切面职责单一

一个切面只负责一个横切关注点，不要在一个切面里混入多种逻辑。

```java
// ✅ 好的做法
@Aspect
public class AuditAspect { ... }  // 只负责审计

@Aspect
public class LogAspect { ... }    // 只负责日志

// ❌ 不好的做法
@Aspect
public class MixedAspect {
    // 同时做审计、日志、权限检查
}
```

### 10.2 切面异常必须捕获

切面内的任何异常都应该被捕获并记录，不能影响主业务。

```java
@Around("smsSendPointcut()")
public Object aroundSmsSend(ProceedingJoinPoint joinPoint) throws Throwable {
    try {
        return joinPoint.proceed();
    } catch (Throwable e) {
        throw e;
    } finally {
        try {
            buildAndSaveLog(...);  // 即使失败也不影响主业务
        } catch (Exception ex) {
            log.error("切面处理异常", ex);
        }
    }
}
```

### 10.3 切入点表达式尽量精确

```java
// ❌ 范围太大，可能拦截不该拦截的方法
@Pointcut("execution(* io.renren.modules..*.*(..))")

// ✅ 精确到具体方法
@Pointcut("execution(* io.renren.modules.open.service.impl.CommonApiServiceImpl.smsSend(..))")
```

---

## 总结

| 核心原则 | 说明 |
|---------|------|
| 只拦截 Spring Bean | 手动 new 的对象不会被拦截 |
| 同类调用不生效 | `this.method()` 不走代理 |
| 异常必须抛出 | 吞掉异常会导致调用方误判 |
| 耗时操作要异步 | 切面内不要阻塞主流程 |
| 引用路径要正确 | 找不到类会导致切面失败 |
| 职责要单一 | 一个切面只做一件事 |

> **一句话总结：** AOP 很强大，但要记住它只拦截 Spring 管理的 Bean 的 public 方法，且同类内部调用不生效。
